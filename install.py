#!/usr/bin/env python3
import os
import sys
import shutil
import argparse
import subprocess
from argparse import RawTextHelpFormatter


global OUTDIR


def out_dir(func):
    def func_wrapper(*args, **kwargs):
        current_loc = os.getcwd()
        outdir = OUTDIR
        if not os.path.exists(outdir):
            os.makedirs(outdir)
        os.chdir(outdir)
        func(*args, **kwargs)
        os.chdir(current_loc)

    return func_wrapper


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


@out_dir
def clone_build_biometadb():
    BIOMETADB_URL = "https://github.com/cjneely10/BioMetaDB.git"
    subprocess.run(["git", "clone", BIOMETADB_URL], check=True)
    os.chdir("BioMetaDB")
    subprocess.run(["python3", "setup.py", "build_ext", "--inplace"], check=True)


@out_dir
def download_docker():
    DOCKER_VERSION = "cjneely10/MetaSanity:v0.1.0"
    subprocess.run(["docker", "pull", DOCKER_VERSION], check=True)


@out_dir
def config_pull():
    os.makedirs("Sample/Config")


@out_dir
def download_metasanity():
    METASANITY_URL = "https://github.com/cjneely10/MetaSanity/blob/master/run_pipedm.py"


if __name__ == "__main__":
    ap = ArgParse(
        (
            (("-o", "--outdir"),
             {"help": "Location to which to download MetaSanity package", "required": True}),
            (("-v", "--version"),
             {"help": "Default: docker", "default": "docker"}),
        ),
        description="Download MetaSanity package"
    )

    OUTDIR = ap.args.outdir
    # Pull BioMetaDB program and build
    clone_build_biometadb()
    # Download given version
    if ap.args.version == "docker":
        download_docker()
    # Pull config version
    config_pull()
