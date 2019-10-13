#!/usr/bin/env python3
import os
import argparse
import shutil
import subprocess
from argparse import RawTextHelpFormatter


global OUTDIR, VERSION, CURRENT_VERSION


versions = {
    "v1": {
        "biometadb": "v0.1.0",
        "metasanity_docker": "v0.1.0",
        "metasanity_script": "v0.0.3",
    },
    "v1.1": {
        "biometadb": "v0.1.1",
        "metasanity_docker": "v0.1.1",
        "metasanity_script": "v0.0.4",
    }
}


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
    if os.path.exists("BioMetaDB"):
        shutil.rmtree("BioMetaDB")
    subprocess.run(["git", "clone", BIOMETADB_URL], check=True)
    os.chdir("BioMetaDB")
    subprocess.run(["git", "checkout", versions[CURRENT_VERSION]["biometadb"]], check=True)


@out_dir
def build_biometadb():
    os.chdir("BioMetaDB")
    subprocess.run(["pip3", "install", "-r", "requirements.txt"])
    subprocess.run(["python3", "setup.py", "build_ext", "--inplace"], check=True)


@out_dir
def download_docker():
    DOCKER_VERSION = "cjneely10/metasanity:%s" % versions[CURRENT_VERSION]["metasanity_docker"]
    subprocess.run(["docker", "pull", DOCKER_VERSION], check=True)


@out_dir
def download_build_sourcecode():
    METASANITY_URL = "https://github.com/cjneely10/MetaSanity.git"
    if os.path.exists("MetaSanity"):
        shutil.rmtree("MetaSanity")
    subprocess.run(["git", "clone", METASANITY_URL], check=True)
    os.chdir("MetaSanity")
    subprocess.run(["git", "checkout", versions[CURRENT_VERSION]["metasanity_script"]], check=True)
    subprocess.run(["pip3", "install", "-r", "requirements.txt"])
    subprocess.run(["python3", "setup.py", "build_ext", "--inplace"], check=True)


@out_dir
def config_pull():
    config_path = os.path.join("Config", VERSION)
    if not os.path.exists(config_path):
        os.makedirs(config_path)
    os.chdir(config_path)
    for _file in ("FuncSanity.ini", "Complete-FuncSanity.ini", "PhyloSanity.ini", "Complete-PhyloSanity.ini"):
        subprocess.run(["wget",
                        "https://raw.githubusercontent.com/cjneely10/MetaSanity/%s/Sample/Config/%s/%s" %
                        (versions[CURRENT_VERSION]["metasanity_script"], VERSION, _file),
                        "-O", _file],
                       check=True)


@out_dir
def pull_download_script():
    DOWNLOAD_SCRIPT_URL = "https://raw.githubusercontent.com/cjneely10/MetaSanity/%s/download-data.py" % \
                          versions[CURRENT_VERSION]["metasanity_script"]
    subprocess.run(["wget", DOWNLOAD_SCRIPT_URL, "-O", "download-data.py"], check=True)


@out_dir
def download_metasanity():
    METASANITY_URL = "https://raw.githubusercontent.com/cjneely10/MetaSanity/%s/MetaSanity.py" % \
                          versions[CURRENT_VERSION]["metasanity_script"]
    subprocess.run(["wget", METASANITY_URL, "-O", "MetaSanity.py"], check=True)


@out_dir
def pull_versions_json_file():
    VERSIONS_JSON_FILE = "https://raw.githubusercontent.com/cjneely10/MetaSanity/%s/VERSIONS.json" % \
                        versions[CURRENT_VERSION]["metasanity_script"]
    subprocess.run(["wget", VERSIONS_JSON_FILE, "-O", "VERSIONS.json"], check=True)


def docker_image():
    download_docker()


def biometadb():
    clone_biometadb()
    build_biometadb()


def scripts():
    config_pull()
    pull_download_script()
    download_metasanity()
    pull_versions_json_file()


def sourcecode():
    download_build_sourcecode()


def sourcecode_installation():
    sourcecode()
    biometadb()
    scripts()


def docker_installation():
    docker_image()
    biometadb()
    scripts()


if __name__ == "__main__":
    ap = ArgParse(
        (
            (("-s", "--sections"),
             {"help": "Comma-separated list to download. Select from: docker_installation,sourcecode_installation,"
                      "docker_image,sourcecode,biometadb,scripts",
              "default": "docker_installation"}),
            (("-t", "--download_type"),
             {"help": "Download type for scripts. Select from: Docker,SourceCode", "default": "Docker"}),
            (("-v", "--version"),
             {"help": "Version to download. Default: v1.1", "default": "v1.1"})
        ),
        description="Download MetaSanity package"
    )

    assert ap.args.version in versions.keys(), "Invalid version selected."
    CURRENT_VERSION = ap.args.version
    OUTDIR = "MetaSanity"
    sections = ap.args.sections.split(",")
    if "docker_installation" in sections:
        VERSION = "Docker"
    elif "sourcecode_installation" in sections:
        VERSION = "SourceCode"
    else:
        VERSION = ap.args.download_type

    for section in sections:
        try:
            locals()[section]()
        except KeyError:
            print("%s not available" % section)
    exit(0)
