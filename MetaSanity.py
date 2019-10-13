#!/usr/bin/env python3
import os
import sys
import json
import shutil
import argparse
import subprocess
from configparser import RawConfigParser
from argparse import RawTextHelpFormatter

"""
MetaSanity calling script


**********
Prior to first run:

If using the provided `download-data.py` script, provide its download location as the variable DOWNLOAD_DIRECTORY.
Otherwise, ensure that all path arguments are valid and that all required databases are downloaded.
If a certain program will not be used, and the database files are not downloaded, provide any valid directory
or leave the default values. Directory contents are never deleted and are only used to reference stored data.
Ensure that BioMetaDB path is accurate, and that optional program binary paths are valid

**********

"""

# Path to download location
DOWNLOAD_DIRECTORY = "/path/to/MetaSanity"
# Version installation - do not change unless using an older MetaSanity version
VERSION = "v1.1"

# (Optional Source Code installation) Path to pipedm.py
PIPEDM_PATH = "/path/to/MetaSanity/pipedm.py"

# # Recommended program paths
# Extracted interproscan package with binary from  https://github.com/ebi-pf-team/interproscan/wiki/HowToDownload
INTERPROSCAN_FOLDER = "/path/to/interproscan"
# Signalp software package, including binary, from  http://www.cbs.dtu.dk/cgi-bin/nph-sw_request?signalp
SIGNALP_FOLDER = "/path/to/signalp-4.1"
# RNAmmer software package, including binary, from  http://www.cbs.dtu.dk/cgi-bin/nph-sw_request?rnammer
RNAMMER_FOLDER = "/path/to/rnammer-1.2.src"

# # Only edit below if your database files were not gathered using the download-data.py script
# Location of VERSIONS.json should be in installation directory
version_data = json.load(open(os.path.join(DOWNLOAD_DIRECTORY, "VERSIONS.json"), "r"))
# Location of BioMetaDB on system. If not used, ensure to pass `-a` flag to MetaSanity.py when running
BIOMETADB = os.path.join(DOWNLOAD_DIRECTORY, "BioMetaDB/dbdm.py")
# Location of databases
DOWNLOAD_DIRECTORY = os.path.join(DOWNLOAD_DIRECTORY, "databases")
# Data downloaded from  https://data.ace.uq.edu.au/public/gtdbtk/
GTDBTK_FOLDER = os.path.join(DOWNLOAD_DIRECTORY, "gtdbtk/release89")
# Extracted checkm data from  https://data.ace.uq.edu.au/public/CheckM_databases/
CHECKM_FOLDER = os.path.join(DOWNLOAD_DIRECTORY, "checkm")
# Directory containing extracted ko_list and profiles/ from  ftp://ftp.genome.jp/pub/db/kofam/
KOFAM_FOLDER = os.path.join(DOWNLOAD_DIRECTORY, "kofamscan")
# Directory containing 3 files - merops-as-pfams.txt, dbCAN-fam-HMMs.txt, MEROPS.pfam.hmm
PEPTIDASE_DATA_FOLDER = os.path.join(DOWNLOAD_DIRECTORY, "peptidase")
# Extracted virsorter data from  https://github.com/simroux/VirSorter
VIRSORTER_DATA_FOLDER = os.path.join(DOWNLOAD_DIRECTORY, "virsorter/virsorter-data")

# MetaSanity version
DOCKER_IMAGE = "cjneely10/metasanity:%s" % version_data[VERSION]["metasanity_docker"]


class ArgParse:

    def __init__(self, arguments_list, description, *args, **kwargs):
        """ Class for handling parsing of arguments and error handling

        """
        self.arguments_list = arguments_list
        self.args = []
        # Instantiate ArgumentParser
        self.parser = argparse.ArgumentParser(formatter_class=RawTextHelpFormatter, description=description,
                                              *args, **kwargs)
        # Add all arguments stored in self.arguments_list
        self._parse_arguments()
        # Parse arguments
        try:
            self.args = self.parser.parse_args()
        except:
            exit(1)

    def _parse_arguments(self):
        """ Protected method for adding all arguments stored in self.arguments_list
            Checks value of "require" and sets accordingly

        """
        for args in self.arguments_list:
            self.parser.add_argument(*args[0], **args[1])

    @staticmethod
    def description_builder(header_line, help_dict, flag_dict):
        """ Static method provides summary of programs/requirements

        """
        assert set(help_dict.keys()) == set(flag_dict.keys()), "Program names do not match in key/help dictionaries"
        to_return = header_line + "\n\nAvailable Programs:\n\n"
        programs = sorted(flag_dict.keys())
        for program in programs:
            to_return += program + ": " + help_dict[program] + "\n\t" + \
                         "\t(Flags: {})".format(" --" + " --".join(flag_dict[program])) + "\n"
        to_return += "\n"
        return to_return


class GetDBDMCall:
    def __init__(self, calling_script_path, _db_name, cancel_autocommit, added_flags=[]):
        """ Class handles determining state of dbdm project

        """
        self.calling_script_path = calling_script_path
        self.db_name = _db_name
        self.cancel_autocommit = cancel_autocommit
        self.added_flags = added_flags

    def run(self, table_name, directory_name, data_file, alias):
        """ Runs dbdm call for specific table_name, etc

        """
        # Commit with biometadb, if passed (COPY/PASTE+REFACTOR from dbdm_calls.pyx)
        to_run = [
            "python3",
            self.calling_script_path,
        ]
        if self.cancel_autocommit:
            return
        if not os.path.isfile(data_file):
            return
        if not os.path.exists(self.db_name):
            to_run.append("INIT")
            to_run.append("-n")
            to_run.append(self.db_name)
        elif os.path.exists(self.db_name) and not os.path.exists(
                os.path.join(self.db_name, "classes", table_name.lower() + ".json")):
            to_run.append("CREATE")
            to_run.append("-c")
            to_run.append(self.db_name)
        elif os.path.exists(self.db_name) and os.path.exists(
                os.path.join(self.db_name, "classes", table_name.lower() + ".json")):
            to_run.append("UPDATE")
            to_run.append("-c")
            to_run.append(self.db_name)
        subprocess.run(
            [
                *to_run,
                "-t",
                table_name.lower(),
                "-a",
                alias.lower(),
                "-f",
                data_file,
                "-d",
                directory_name,
                *self.added_flags,
            ],
            check=True,
        )


def split_phylo_in_evaluation_file(eval_file):
    """ Function takes the 'metagenome_evaluation.tsv' file and corrects the phylogeny

    :param eval_file:
    :return:
    """
    R = open(eval_file, "r")
    W = open(eval_file + ".2", "w")
    # Get header line and phylogeny location
    header = next(R).rstrip("\r\n").split("\t")
    phyl_loc = header.index("phylogeny")
    header[phyl_loc:phyl_loc + 1] = "domain", "phylum", "_class", "_order", "family", "genus", "species"
    W.write("\t".join(header) + "\n")
    for _line in R:
        line = _line.rstrip("\r\n").split("\t")
        line = _line_split(line, phyl_loc)
        W.write("\t".join(line) + "\n")
    W.close()
    shutil.move(eval_file + ".2", eval_file)


def _line_split(line, phyl_loc):
    """ Adjusts location in line to have corrected phylogeny

    :param line:
    :param phyl_loc:
    :return:
    """
    phylogeny_out = line[phyl_loc].split(";")
    # No determination
    if phylogeny_out[0] == "root":
        line[phyl_loc:phyl_loc + 1] = ["None"] * 7
        return line
    # CheckM only
    if len(phylogeny_out) == 1:
        line[phyl_loc:phyl_loc + 1] = [line[phyl_loc].replace("k__", "")] + ["None"] * 6
        return line
    # GTDB-Tk
    int_data = [val.split("__")[1] if val.split("__")[1] != "" else "None" for val in line[phyl_loc].split(";")]
    int_data[-1] = (int_data[-1].split(" ")[1] if int_data[-1].split(" ") != ["None"] else "None")
    line[phyl_loc:phyl_loc + 1] = int_data
    return line


def get_added_flags(config, _dict):
    """ Function returns FLAGS line from dict in config file

    """
    if "FLAGS" in dict(config[_dict]).keys():
        return [def_key.lstrip(" ").rstrip(" ")
                for def_key in config[_dict]["FLAGS"].rstrip("\r\n").split(",")
                if def_key != ""]
    else:
        return []


def determine_paths_to_add(path, add_string=""):
    """ Determines if optional program path is valid
    Returns list with correct path in docker volume-like standard
    Or returns empty list

    :param path:
    :param add_string:
    :return:
    """
    if os.path.exists(path):
        return ["-v", path + add_string]
    return []


# Parsed arguments
ap = ArgParse(
    (
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
        (("-p", "--prokka"),
         {"help": "Use PROKKA gene calls instead of prodigal search", "default": False, "action": "store_true"}),
        (("-z", "--autoremove_intermediates"),
         {"help": "Remove intermediary genome directories, default: True", "default": True, "action": "store_false"}),
        (("-r", "--reevaluate_quality"),
         {"help": "Redetermine genome quality as High/Medium/Low/Incomplete (PhyloSanity must be complete)",
          "default": False, "action": "store_true"})
    ),
    description=ArgParse.description_builder(
        "MetaSanity:\tRun meta/genomes evaluation and annotation pipelines",
        {
            "PhyloSanity": "Evaluates completion, contamination, and redundancy of MAGs",
            "FuncSanity": "Runs gene callers and annotation programs on MAGs",
        },
        {
            "PhyloSanity": ("directory", "config_file", "cancel_autocommit", "output_directory",
                            "biometadb_project"),
            "FuncSanity": ("directory", "config_file", "cancel_autocommit", "output_directory",
                           "biometadb_project", "type_file", "prokka", "reevaluate_quality"),
        }
    )
)

# Config file read in
cfg = RawConfigParser()
cfg.optionxform = str
cfg.read(ap.args.config_file)

met_list = {
    "PhyloSanity": "metagenome_evaluation.list",
    "FuncSanity": "metagenome_annotation.list"
}

prokka_add = []
if ap.args.prokka:
    prokka_add = ["--prokka"]

# Determine which volumes to connect to docker image
interproscan_add = determine_paths_to_add(INTERPROSCAN_FOLDER, ":/home/appuser/interproscan-5.32-71.0")
signalp_add = determine_paths_to_add(SIGNALP_FOLDER, ":/home/appuser/signalp")
rnammer_add = determine_paths_to_add(RNAMMER_FOLDER, ":/home/appuser/rnammer")
checkm_add = determine_paths_to_add(CHECKM_FOLDER, ":/home/appuser/checkm")
gtdbtk_add = determine_paths_to_add(GTDBTK_FOLDER, ":/home/appuser/gtdbtk/db")
kofamscan_add = determine_paths_to_add(KOFAM_FOLDER, ":/home/appuser/kofamscan/db")
peptidase_add = determine_paths_to_add(PEPTIDASE_DATA_FOLDER, ":/home/appuser/Peptidase")
virsorter_add = determine_paths_to_add(VIRSORTER_DATA_FOLDER, ":/home/appuser/virsorter-data")

cid_file_name = 'docker.pid'

# Run docker version
if not os.path.exists(PIPEDM_PATH):
    try:
        subprocess.run(
            [
                "docker",
                "run",
                # user info
                "--user",
                subprocess.getoutput("id -u"),
                "--cidfile",
                cid_file_name,
                # Locale setup required for parsing files
                "-e",
                "LANG=C.UTF-8",
                # CheckM
                *checkm_add,
                # GTDBtk
                *gtdbtk_add,
                # kofamscan
                *kofamscan_add,
                # Peptidase storage
                *peptidase_add,
                # Interproscan
                *interproscan_add,
                # Volume to access genomes
                *virsorter_add,
                # Volume to access signalp binary
                *signalp_add,
                # Volume to access rnammer binary
                *rnammer_add,
                # Change output directory here
                "-v", os.getcwd() + ":/home/appuser/wdir",
                # "-it",
                "--rm",
                DOCKER_IMAGE,
                ap.args.program,
                "-d", os.path.join("/home/appuser/wdir", os.path.relpath(ap.args.directory)),
                "-o", os.path.join("/home/appuser/wdir", os.path.relpath(ap.args.output_directory)),
                "-c", os.path.join("/home/appuser/wdir", os.path.relpath(ap.args.config_file)),
                "-t", (os.path.join("/home/appuser/wdir", os.path.relpath(ap.args.type_file))
                       if ap.args.type_file != "None" else "None"),
                *prokka_add,
                # Notify that this was called from docker
                "-y",
                # Cancel autocommit from docker
                "-a",
                # Don't remove intermediary files
                "-z"
            ],
            check=True,
        )
        os.remove(cid_file_name)
    except KeyboardInterrupt:
        print("\nExiting...")
        try:
            subprocess.run(["docker", "kill", open(cid_file_name, "rb").read()], check=True)
            os.remove(cid_file_name)
            sys.exit(1)
        except KeyboardInterrupt:
            os.remove(cid_file_name)
            sys.exit(1)
        except FileNotFoundError:
            sys.exit(1)
    except subprocess.CalledProcessError:
        try:
            os.remove(cid_file_name)
            sys.exit(1)
        except FileNotFoundError:
            sys.exit(1)
else:
    try:
        subprocess.run(
            [
                "python3",
                PIPEDM_PATH,
                ap.args.program,
                "-d", os.path.relpath(ap.args.directory),
                "-o", os.path.relpath(ap.args.output_directory),
                "-c", os.path.relpath(ap.args.config_file),
                "-t", (os.path.relpath(ap.args.type_file) if ap.args.type_file != "None" else "None"),
                *prokka_add,
                "-a",
                "-z",
            ],
            check=True,
        )
    except KeyboardInterrupt:
        sys.exit(1)

out_prefixes = set({})

if not ap.args.cancel_autocommit and os.path.exists(os.path.join(ap.args.output_directory, met_list[ap.args.program])):
    print("\nStoring results to database..........")
    # Primary output file types from FuncSanity (with N = number of genomes):
    # Set project name
    try:
        db_name = (ap.args.biometadb_project
                   if ap.args.biometadb_project != "None"
                   else cfg.get("BIOMETADB", "--db_name"))
    except:
        db_name = "MetagenomeAnnotation"

    dbdm = GetDBDMCall(BIOMETADB, db_name, ap.args.cancel_autocommit, get_added_flags(cfg, "BIOMETADB"))
    if ap.args.program == "FuncSanity":
        dbdm.run(
            "functions",
            os.path.join(ap.args.output_directory, "genomes"),
            os.path.join(ap.args.output_directory, "metagenome_functions.tsv"),
            "functions",
        )
        # Begin commit individual genomes info
        # Based on file names in metagenome_annotation.list
        for genome_prefix in (os.path.splitext(os.path.basename(line.rstrip("\r\n")))[0]
                              for line in open(os.path.join(ap.args.output_directory, met_list[ap.args.program]))):
            # Virsorter out (N) - out/virsorter_results/*/virsorter-out/*.VIRSorter_adj_out.tsv
            print("\nStoring %s to database.........." % genome_prefix)
            out_prefixes.add(genome_prefix)
            dbdm.run(
                genome_prefix.lower(),
                os.path.join(ap.args.output_directory, "splitfiles", genome_prefix + ".fna"),
                os.path.join(ap.args.output_directory, "virsorter_results", genome_prefix, "virsorter-out",
                             "%s.VIRSorter_adj_out.tsv" % genome_prefix),
                genome_prefix.lower(),
            )
            # Combined Results (N) - out/*.metagenome_annotation.tsv
            dbdm.run(
                genome_prefix.lower(),
                os.path.join(ap.args.output_directory, "splitfiles", genome_prefix),
                os.path.join(ap.args.output_directory, "%s.metagenome_annotation.tsv" % genome_prefix),
                genome_prefix.lower(),
            )
    elif ap.args.program == "PhyloSanity":
        eval_file = os.path.join(ap.args.output_directory, "metagenome_evaluation.tsv")
        split_phylo_in_evaluation_file(eval_file)
        dbdm.run(
            "evaluation",
            os.path.join(ap.args.output_directory, "genomes"),
            os.path.join(ap.args.output_directory, "metagenome_evaluation.tsv"),
            "evaluation",
        )
    print("BioMetaDB project complete!")

if ap.args.reevaluate_quality:
    pass

if ap.args.program == "FuncSanity":
    for prefix in out_prefixes:
        if os.path.exists(os.path.join(ap.args.output_directory, prefix + ".metagenome_annotation_tmp.tsv")):
            os.remove(os.path.join(ap.args.output_directory, prefix + ".metagenome_annotation_tmp.tsv"))

if ap.args.autoremove_intermediates:
    shutil.rmtree(os.path.join(ap.args.output_directory, "genomes"))
    shutil.rmtree(os.path.join(ap.args.output_directory, "splitfiles"))
