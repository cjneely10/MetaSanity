# cython: language_level=3

import os
from pathlib import Path
from configparser import NoSectionError, NoOptionError
from MetaSanity.Config.config import Config
from MetaSanity.Peptidase.cazy import CAZYConstants
from MetaSanity.Annotation.prokka import PROKKAConstants
from MetaSanity.Peptidase.peptidase import PeptidaseConstants
from MetaSanity.Annotation.kofamscan import KofamScanConstants
from MetaSanity.Annotation.virsorter import VirSorterConstants
from MetaSanity.Annotation.interproscan import InterproscanConstants
from MetaSanity.PipelineManagement.citation_generator import CitationGenerator

pipelines = {
    "annotation": {
        "required": ["PRODIGAL", "HMMSEARCH", "HMMCONVERT", "HMMPRESS", "DIAMOND"],
        "peptidase": ["CAZY", "MEROPS"],
        "kegg": ["KOFAMSCAN", "BIODATA",],
        "prokka": ["PROKKA",],
        "interproscan": ["INTERPROSCAN",],
        "virsorter": ["VIRSORTER",],
    },
    "evaluation": {
        "required": ["CHECKM", "FASTANI",],
        "gtdbtk": ["GTDBTK",],
    },
}

pipeline_classes = {
    "virsorter": (VirSorterConstants.ADJ_OUT_FILE,),
    "interproscan": (InterproscanConstants.AMENDED_RESULTS_SUFFIX,),
    "prokka": (PROKKAConstants.FINAL_RESULTS_SUFFIX, PROKKAConstants.OUT_ADDED),
    "kegg": (KofamScanConstants.AMENDED_RESULTS_SUFFIX,),
    "peptidase": (CAZYConstants.ASSIGNMENTS_BY_PROTEIN, PeptidaseConstants.EXTRACELLULAR_MATCHES_BYPROT_EXT),
}


class ConfigManager:
    """ Class will load Config file and determine values for given programs in pipeline based
    on environment values and default settings

    """

    PATH = "PATH"
    DATA = "DATA"
    DATA_DICT = "DATA_DICT"

    def __init__(self, str config_path, tuple ignore = (), str pipeline_name = None):
        self.config = Config()
        self.config.optionxform = str
        self.config.read(config_path)
        self.ignore = ignore
        self.completed_tests = set()
        self.citation_generator = CitationGenerator()
        # Check pipeline's required paths/data
        if pipeline_name:
            self.check_pipe_set("required", pipeline_name)

    def get(self, str _dict, str value):
        """ Gets value from either environment variable or from Config file,
        Returns None otherwise

        :param _dict:
        :param value: (str) Value to get from Config file
        :return:
        """
        if value != "PATH":
            return os.environ.get(value) or self.config.get(_dict, value)
        try:
            return self.config.get(_dict, value)
        except KeyError:
            return None
        except NoOptionError:
            return "None"
        except NoSectionError:
            return "None"

    def build_parameter_list_from_dict(self, str _dict, tuple ignore = ()):
        """ Creates list of parameters from given values in given Config dict section
        Ignores areas set on initialization as well as those passed to this function
        Automatically ignores values with "path" in name

        :param ignore:
        :param _dict:
        :return:
        """
        if _dict not in self.config.keys():
            return []
        cdef list parameter_list = []
        cdef str def_key, key
        cdef int i
        cdef list params = [
            key for key in self.config[_dict].keys()
            if key not in ignore
               and key not in self.ignore
               and "PATH" not in key
        ]
        for i in range(len(params)):
            if params[i] != "FLAGS":
                parameter_list.append(params[i])
                parameter_list.append(self.config[_dict][params[i]])
            # Treat values set using FLAGS as a comma-separated list
            else:
                for def_key in self.config[_dict][params[i]].rstrip("\r\n").split(","):
                    def_key = def_key.lstrip(" ").rstrip(" ")
                    parameter_list.append(def_key)
        return parameter_list

    def get_cutoffs(self):
        return dict(self.config["CUTOFFS"])

    def get_added_flags(self, str _dict, tuple ignore = ()):
        """ Method returns FLAGS line from dict in config file

        :param _dict:
        :param ignore:
        :return:
        """
        if "FLAGS" in dict(self.config[_dict]).keys():
            return [def_key.lstrip(" ").rstrip(" ")
                    for def_key in self.config[_dict]["FLAGS"].rstrip("\r\n").split(",")
                    if def_key != ""]
        else:
            return []

    def check_pipe_set(self, str pipe, str pipeline_name):
        """ Method checks if all required programs have entries in config file.

        Returns true/false. Does not check validity of programs

        :param pipe:
        :param pipeline_name:
        :return:
        """
        cdef str program, key
        cdef object value, _path
        # Allows pipe checks to only run once
        if pipe in self.completed_tests:
            return True
        if pipe == "peptidase" and "SIGNALP" in self.config.keys():
            value = self.config["SIGNALP"]
            self.citation_generator.add("signalp", self.build_parameter_list_from_dict("SIGNALP"))
        for program in pipelines[pipeline_name][pipe]:
            # Verify that the [PROGRAM] is present for the given pipe
            try:
                # value has PROGRAM:{key:val} structure
                value = self.config[program]
                # Check PATH, DATA, and DATA_DICT paths
                self.citation_generator.add(program, self.build_parameter_list_from_dict(program))
                for key in ("PATH", "DATA", "DATA_DICT"):
                    if key in value.keys() and not os.path.exists(str(Path(value[key]).resolve())):
                        print("%s for %s not found" % (key, program))
                        exit(1)
            except NoSectionError:
                if pipe == "required":
                    print("%s not found" % program)
                    exit(1)
                return False
            except KeyError:
                if pipe == "required":
                    print("%s not found" % program)
                    exit(1)
                return False
        self.completed_tests.add(pipe)
        return True
