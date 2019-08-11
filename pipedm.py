#!/usr/bin/env python3

from MetaSanity.Accessories.arg_parse import ArgParse
from MetaSanity.Accessories.program_caller import ProgramCaller
from MetaSanity.Pipeline.metagenome_evaluation import metagenome_evaluation
from MetaSanity.Pipeline.metagenome_annotation import metagenome_annotation

if __name__ == "__main__":
    args_list = (
        (("program",),
         {"help": "Program to run"}),
        (("-d", "--directory"),
         {"help": "Directory containing genomes", "required": True}),
        (("-c", "--config_file"),
         {"help": "Config file", "required": True}),
        (("-a", "--cancel_autocommit"),
         {"help": "Cancel commit to database", "action": "store_true", "default": False}),
        (("-o", "--output_directory"),
         {"help": "Output directory prefix, default out", "default": "out"}),
        (("-b", "--biometadb_project"),
         {"help": "/path/to/BioMetaDB_project (updates values of existing database)", "default": "None"}),
        (("-t", "--type_file"),
         {"help": "/path/to/type_file formatted as 'file_name.fna\\t[Archaea/Bacteria]\\t[gram+/gram-]\\n'",
          "default": "None"}),
        (("-y", "--is_docker"),
         {"help": "For use in docker version", "default": False, "action": "store_true"}),
        (("-z", "--remove_intermediates"),
         {"help": "For use in docker version", "default": True, "action": "store_false"}),
        (("-p", "--prokka"),
         {"help": "Use PROKKA gene calls instead of prodigal search", "default": False, "action": "store_true"}),
    )

    programs = {
        "PhyloSanity": metagenome_evaluation,
        "FuncSanity": metagenome_annotation,

    }

    flags = {
        "PhyloSanity": ("directory", "config_file", "cancel_autocommit", "output_directory",
                        "biometadb_project", "is_docker", "remove_intermediates"),
        "FuncSanity": ("directory", "config_file", "cancel_autocommit", "output_directory",
                       "biometadb_project", "type_file", "is_docker", "remove_intermediates", "prokka"),
    }

    errors = {

    }

    _help = {
        "PhyloSanity": "Evaluates completion, contamination, and redundancy of MAGs",
        "FuncSanity": "Runs gene callers and annotation programs on MAGs",
    }

    ap = ArgParse(
        args_list,
        description=ArgParse.description_builder(
            "MetaSanity:\tRun meta/genomes evaluation and annotation pipelines",
            _help,
            flags
        )
    )
    pc = ProgramCaller(
        programs=programs,
        flags=flags,
        _help=_help,
        errors=errors
    )
    pc.run(ap.args, debug=True)
