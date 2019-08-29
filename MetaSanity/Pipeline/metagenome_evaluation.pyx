# cython: language_level=3
import os
import luigi
import shutil
from MetaSanity.Database.dbdm_calls import GetDBDMCall, BioMetaDBConstants
from MetaSanity.Config.config_manager import ConfigManager
from MetaSanity.AssemblyEvaluation.checkm import CheckM, CheckMConstants
from MetaSanity.AssemblyEvaluation.gtdbtk import GTDBtk, GTDBTKConstants
from MetaSanity.MetagenomeEvaluation.fastani import FastANI, FastANIConstants
from MetaSanity.MetagenomeEvaluation.redundancy_checker import RedundancyParserTask
from MetaSanity.PipelineManagement.citation_generator import CitationManagerConstants
from MetaSanity.PipelineManagement.project_manager cimport project_check_and_creation
from MetaSanity.PipelineManagement.project_manager import GENOMES


"""
genome_evaluation runs CheckM, GTDBtk, fastANI, and parses output into a BioMetaDB project
Uses assembled genomes (.fna)

"""


class MetagenomeEvaluationConstants:
    TABLE_NAME = "evaluation"
    TSV_OUT = "metagenome_evaluation.tsv"
    LIST_FILE = "metagenome_evaluation.list"
    PROJECT_NAME = "MetagenomeEvaluation"
    PIPELINE_NAME = "metagenome_evaluation"


def metagenome_evaluation(str directory, str config_file, bint cancel_autocommit, str output_directory,
                      str biometadb_project, bint is_docker, bint remove_intermediates):
    """ Function calls the pipeline for evaluating a set of genomes using checkm, gtdbtk, fastANI
    Creates .tsv file of final output, adds to database

    :param directory:
    :param config_file:
    :param cancel_autocommit:
    :param output_directory:
    :param biometadb_project:
    :param remove_intermediates:
    :param is_docker:
    :return:
    """
    cdef str genome_list_path, alias, table_name
    cdef object cfg, task
    genome_list_path, alias, table_name, cfg, biometadb_project = project_check_and_creation(
        <void* >directory,
        <void* >config_file,
        <void* >output_directory,
        biometadb_project,
        MetagenomeEvaluationConstants
    )
    directory = os.path.join(output_directory, GENOMES)
    cdef list task_list = []
    # Optional task - phylogeny prediction
    if cfg.check_pipe_set("gtdbtk", MetagenomeEvaluationConstants.PIPELINE_NAME):
        task_list.append(
            GTDBtk(
                output_directory=os.path.join(output_directory, GTDBTKConstants.OUTPUT_DIRECTORY),
                added_flags=cfg.build_parameter_list_from_dict(GTDBTKConstants.GTDBTK),
                fasta_folder=directory,
                calling_script_path=cfg.get(GTDBTKConstants.GTDBTK, ConfigManager.PATH),
            ),
        )
    for task in (
        # Required task - determine completeness and contamination
        CheckM(
            output_directory=os.path.join(output_directory, CheckMConstants.OUTPUT_DIRECTORY),
            fasta_folder=directory,
            added_flags=cfg.build_parameter_list_from_dict(CheckMConstants.CHECKM),
            calling_script_path=cfg.get(CheckMConstants.CHECKM, ConfigManager.PATH),
        ),
        # Required task - determine average nucleotide identity among list of genomes
        FastANI(
            output_directory=os.path.join(output_directory, FastANIConstants.OUTPUT_DIRECTORY),
            added_flags=cfg.build_parameter_list_from_dict(FastANIConstants.FASTANI),
            listfile_of_fasta_with_paths=genome_list_path,
            calling_script_path=cfg.get(FastANIConstants.FASTANI, ConfigManager.PATH),
        ),
        # Required task - determine redundancy and quality
        RedundancyParserTask(
            checkm_output_file=os.path.join(output_directory, CheckMConstants.OUTPUT_DIRECTORY, CheckMConstants.OUTFILE),
            fastANI_output_file=os.path.join(output_directory, FastANIConstants.OUTPUT_DIRECTORY,
                                             FastANIConstants.OUTFILE),
            gtdbtk_output_file=os.path.join(output_directory, GTDBTKConstants.OUTPUT_DIRECTORY,
                                            GTDBTKConstants.GTDBTK + GTDBTKConstants.BAC_OUTEXT),
            cutoffs_dict=cfg.get_cutoffs(),
            file_ext_dict={os.path.basename(os.path.splitext(file)[0]): os.path.splitext(file)[1]
                           for file in os.listdir(directory)},
            calling_script_path="None",
            outfile=MetagenomeEvaluationConstants.TSV_OUT,
            output_directory=output_directory,
        ),
    ):
        task_list.append(task)
    task_list.append(
        GetDBDMCall(
            cancel_autocommit=cancel_autocommit,
            table_name=table_name,
            alias=alias,
            calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
            db_name=biometadb_project,
            directory_name=directory,
            data_file=os.path.join(output_directory, MetagenomeEvaluationConstants.TSV_OUT),
            added_flags=cfg.get_added_flags(BioMetaDBConstants.BIOMETADB),
            storage_string="evaluation results"
        )
    )
    luigi.build(task_list, local_scheduler=True)
    cfg.citation_generator.write(os.path.join(output_directory, CitationManagerConstants.OUTPUT_FILE))
    if remove_intermediates:
        shutil.rmtree(directory)
    print("PhyloSanity pipeline complete!")
