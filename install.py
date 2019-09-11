#!/usr/bin/env python3
import os
import argparse
import subprocess
from argparse import RawTextHelpFormatter


global OUTDIR


def out_dir(func):
    def func_wrapper(*args, **kwargs):
        current_loc = os.getcwd()
        if not os.path.exists(OUTDIR):
            os.makedirs(OUTDIR)
        os.chdir(OUTDIR)
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
def clone_biometadb():
    BIOMETADB_URL = "https://github.com/cjneely10/BioMetaDB.git"
    if not os.path.exists("BioMetaDB"):
        subprocess.run(["git", "clone", BIOMETADB_URL], check=True)
    else:
        os.chdir("BioMetaDB")
        subprocess.run(["git", "pull", BIOMETADB_URL], check=True)


@out_dir
def build_biometadb():
    os.chdir("BioMetaDB")
    subprocess.run(["pip", "install", "-r", "requirements.txt"])
    subprocess.run(["python3", "setup.py", "build_ext", "--inplace"], check=True)


@out_dir
def download_docker():
    DOCKER_VERSION = "cjneely10/metasanity:v0.1.0"
    subprocess.run(["docker", "pull", DOCKER_VERSION], check=True)


@out_dir
def config_pull(version):
    config_path = os.path.join("Config", version)
    if not os.path.exists(config_path):
        os.makedirs(config_path)
    os.chdir(config_path)
    if version == "Docker":
        subprocess.run(["wget",
                        "https://raw.githubusercontent.com/cjneely10/MetaSanity/master/Sample/Config/Docker"
                        "/FuncSanity.ini",
                        "-O", "FuncSanity.ini"],
                       check=True)
        subprocess.run(["wget",
                        "https://raw.githubusercontent.com/cjneely10/MetaSanity/master/Sample/Config/Docker"
                        "/PhyloSanity.ini",
                        "-O", "PhyloSanity.ini"],
                       check=True)


@out_dir
def pull_download_script():
    DOWNLOAD_SCRIPT_URL = "https://raw.githubusercontent.com/cjneely10/MetaSanity/master/download-data.py"
    subprocess.run(["wget", DOWNLOAD_SCRIPT_URL, "-O", "download-data.py"], check=True)
    subprocess.run(["chmod", "+x", os.path.basename(DOWNLOAD_SCRIPT_URL)], check=True)


@out_dir
def download_metasanity():
    METASANITY_URL = "https://raw.githubusercontent.com/cjneely10/MetaSanity/master/MetaSanity.py"
    subprocess.run(["wget", METASANITY_URL, "-O", "MetaSanity.py"], check=True)
    subprocess.run(["chmod", "+x", os.path.basename(METASANITY_URL)], check=True)


if __name__ == "__main__":
    ap = ArgParse(
        (
            (("-o", "--outdir"),
             {"help": "Location to which to download MetaSanity package, default MetaSanity", "default": "MetaSanity"}),
            (("-v", "--version"),
             {"help": "Default: Docker", "default": "Docker"}),
        ),
        description="Download MetaSanity package"
    )
    assert ap.args.version in ("Docker",), "Incorrect version, select from: Docker"
    OUTDIR = ap.args.outdir
    # Get BioMetaDB
    clone_biometadb()
    build_biometadb()
    # Download given version
    if ap.args.version == "Docker":
        download_docker()
    # Download config files for version
    config_pull(ap.args.version)
    pull_download_script()
    download_metasanity()
