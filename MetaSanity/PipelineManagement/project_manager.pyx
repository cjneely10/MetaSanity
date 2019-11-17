import os
import shutil
from configparser import NoOptionError
from MetaSanity.Pipeline.Exceptions.GeneralAssertion import AssertString
from MetaSanity.Config.config_manager import ConfigManager
from MetaSanity.Database.dbdm_calls import BioMetaDBConstants
from MetaSanity.Parsers.fasta_parser import FastaParser
from MetaSanity.Accessories.ops import get_prefix


cdef str OUTPUT_DIRECTORY = "OUTPUT_DIRECTORY"
cdef str LIST_FILE = "LIST_FILE"
cdef str PIPELINE_NAME = "PIPELINE_NAME"
cdef str PROJECT_NAME = "PROJECT_NAME"
cdef str TABLE_NAME = "TABLE_NAME"
GENOMES = "genomes"


cdef tuple project_check_and_creation(void* directory, void* config_file, void* output_directory, str biometadb_project,
                               object CallingClass):
    """
    
    :param directory: 
    :param config_file: 
    :param output_directory: 
    :param biometadb_project: 
    :param CallingClass: 
    :return: 
    """
    # Ensure that all values are valid
    assert os.path.isdir((<object>directory)) and os.path.isfile((<object>config_file)), \
        AssertString.INVALID_PARAMETERS_PASSED
    # Load config file as object
    cdef object cfg = ConfigManager((<object>config_file), pipeline_name=getattr(CallingClass, PIPELINE_NAME))
    # Declaration for iteration
    cdef object val
    cdef str genome_storage_folder = os.path.join((<object>output_directory), GENOMES)
    print("Creating output directories")
    # # Remove old directory from prior run, if available
    if not os.path.exists((<object>output_directory)):
        os.makedirs((<object>output_directory))
    if not os.path.exists(genome_storage_folder):
        shutil.rmtree(genome_storage_folder)
    os.makedirs(genome_storage_folder)
    # Declarations
    cdef str _file, _f
    cdef tuple split_file
    cdef list current_files = os.listdir(genome_storage_folder)
    cdef str genome_list_path = os.path.join((<object>output_directory), getattr(CallingClass, LIST_FILE))
    # Copy all genomes to folder with temporary file
    print("Reformatting input files and moving to temp directory")
    for _file in os.listdir((<object>directory)):
        if os.path.getsize(os.path.join((<object>directory), os.path.basename(_file))) != 0:
            _f = os.path.splitext(_file.replace("_", "-"))[0].replace(".", "-").lower() + ".fna"
            if _f not in current_files:
                FastaParser.write_simple(
                    os.path.join((<object>directory), _file),
                    os.path.join(genome_storage_folder, _f),
                    simplify=adj_string_to_length(get_prefix(_f), 20, .7),
                )
    # Declarations
    cdef str alias
    cdef str table_name
    # Write list of all files in directory as a list file
    write_genome_list_to_file((<void *>genome_storage_folder), (<void *>genome_list_path))
    # Load biometadb info
    if (<object>biometadb_project) == "None":
        try:
            biometadb_project = cfg.get(BioMetaDBConstants.BIOMETADB, BioMetaDBConstants.DB_NAME)
        except NoOptionError:
            biometadb_project = getattr(CallingClass, PROJECT_NAME)
    # Get table name from config file or default
    try:
        table_name = cfg.get(BioMetaDBConstants.BIOMETADB, BioMetaDBConstants.TABLE_NAME)
    except NoOptionError:
        table_name = getattr(CallingClass, TABLE_NAME)
    # Get alias from config file or default
    try:
        alias = cfg.get(BioMetaDBConstants.BIOMETADB, BioMetaDBConstants.ALIAS)
    except NoOptionError:
        alias = getattr(CallingClass, TABLE_NAME)
    return genome_list_path, alias, table_name, cfg, biometadb_project


cdef void write_genome_list_to_file(void* directory, void* outfile):
    """  Function writes list to file

    :param directory:
    :param outfile:
    :return:
    """
    cdef str _file
    cdef object W = open((<object>outfile), "w")
    for _file in os.listdir((<object>directory)):
        W.write("%s\n" % os.path.join((<object>directory), os.path.splitext(_file.replace("_", "-"))[0].lower() + ".fna"))
    W.close()

cdef str adj_string_to_length(str to_adjust, int max_length, double split_ratio):
    """ Function takes a string and shrinks it, retaining ends based on ratio
    
    :param to_adjust: 
    :param max_length: 
    :param split_ratio: 
    :return: 
    """
    if len(to_adjust) <= max_length:
        return to_adjust
    cdef int front_split_loc = int(max_length * split_ratio)
    cdef int end_split_loc = int(max_length * (1 - split_ratio))
    return "%s%s" % (to_adjust[0: front_split_loc], to_adjust[len(to_adjust) - end_split_loc:])
