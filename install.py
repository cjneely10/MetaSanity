#!/usr/bin/env python3
import os
import argparse
import shutil
import subprocess
from argparse import RawTextHelpFormatter

global VERSION, PACKAGE_VERSION

OUTDIR = "MetaSanity"
DEFAULT_VERSION = "v1.2.0"

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
    },
    "v1.1.1": {
        "biometadb": "v0.1.2",
        "metasanity_docker": "v0.1.2",
        "metasanity_script": "v0.0.5"
    },
    "v1.2.0": {
        "biometadb": "v0.1.3.0",
        "metasanity_docker": "v0.1.2",
        "metasanity_script": "v0.0.6"
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
def download_docker():
    DOCKER_VERSION = "cjneely10/metasanity:%s" % versions[PACKAGE_VERSION]["metasanity_docker"]
    try:
        subprocess.run(["docker", "pull", DOCKER_VERSION], check=True)
    except subprocess.CalledProcessError as e:
        print(e.output)
        exit(1)


@out_dir
def download_build_sourcecode():
    METASANITY_URL = "https://github.com/cjneely10/MetaSanity.git"
    if os.path.exists("MetaSanity"):
        shutil.rmtree("MetaSanity")
    try:
        subprocess.run(["git", "clone", METASANITY_URL], check=True)
        os.chdir("MetaSanity")
        subprocess.run(["git", "checkout", versions[PACKAGE_VERSION]["metasanity_script"]], check=True)
        subprocess.run(["pip3", "install", "-r", "requirements.txt"])
        subprocess.run(["python3", "setup.py", "build_ext", "--inplace"], check=True)
    except subprocess.CalledProcessError as e:
        print(e.output)
        exit(1)


@out_dir
def config_pull():
    config_path = os.path.join("Config", VERSION)
    if not os.path.exists(config_path):
        os.makedirs(config_path)
    os.chdir(config_path)
    for _file in ("FuncSanity.ini", "Complete-FuncSanity.ini", "PhyloSanity.ini", "Complete-PhyloSanity.ini"):
        subprocess.run(["wget",
                        "https://raw.githubusercontent.com/cjneely10/MetaSanity/%s/Sample/Config/%s/%s" %
                        (versions[PACKAGE_VERSION]["metasanity_script"], VERSION, _file),
                        "-O", _file],
                       check=True)


@out_dir
def pull_download_script():
    DOWNLOAD_SCRIPT_URL = "https://raw.githubusercontent.com/cjneely10/MetaSanity/%s/download-data.py" % \
                          versions[PACKAGE_VERSION]["metasanity_script"]
    subprocess.run(["wget", DOWNLOAD_SCRIPT_URL, "-O", "download-data.py"], check=True)


@out_dir
def download_metasanity():
    METASANITY_URL = "https://raw.githubusercontent.com/cjneely10/MetaSanity/%s/MetaSanity.py" % \
                     versions[PACKAGE_VERSION]["metasanity_script"]
    subprocess.run(["wget", METASANITY_URL, "-O", "MetaSanity.py.tmpl"], check=True)
    if os.path.exists("MetaSanity.py"):
        merge_metasanity_files("MetaSanity.py", "MetaSanity.py.tmpl")
        os.remove("MetaSanity.py.tmpl")
    else:
        shutil.move("MetaSanity.py.tmpl", "MetaSanity.py")
        subprocess.run(["sed", "-i",
                        's/DOWNLOAD_DIRECTORY = \"\/path\/to\/MetaSanity\"/DOWNLOAD_DIRECTORY = \"' + os.getcwd().replace(
                            "/", "\/") + '\"/',
                        "MetaSanity.py"])
        if VERSION == 'SourceCode':
            subprocess.run(["sed", "-i",
                            's/PIPEDM_PATH = \"\/path\/to\/MetaSanity\/pipedm.py\"/PIPEDM_PATH = \"' +
                            os.path.join(os.getcwd(), 'MetaSanity/pipedm.py').replace("/", "\/") + '\"/',
                            "MetaSanity.py"])


def merge_metasanity_files(old_file, template_file):
    R = open(old_file, "r")
    T = open(template_file, "r")
    W = open(old_file + ".tmp10111134", "w")
    # Write new file up to data section
    templ_line = next(T)
    while not templ_line.startswith("DOWNLOAD_DIRECTORY"):
        W.write(templ_line)
        templ_line = next(T)

    # Skip over old section up to data
    old_line = next(R)
    while not old_line.startswith("DOWNLOAD_DIRECTORY"):
        old_line = next(R)

    # Skip over template data section
    while not templ_line.startswith("VERSION"):
        templ_line = next(T)

    # Write old data section up to VERSION
    while not old_line.startswith("VERSION"):
        W.write(old_line)
        old_line = next(R)

    # Skip version of old file
    old_line = next(R)

    # Write new version
    W.write(templ_line)

    # Write old data section
    while not old_line.startswith("class ArgParse:"):
        W.write(old_line)
        old_line = next(R)

    # Skip over template data section
    while not templ_line.startswith("class ArgParse:"):
        templ_line = next(T)

    # Write rest of file
    W.write(templ_line)
    for line in T:
        W.write(line)

    shutil.move(old_file, old_file + ".prior")
    shutil.move(old_file + ".tmp10111134", old_file)


@out_dir
def pull_versions_json_file():
    VERSIONS_JSON_FILE = "https://raw.githubusercontent.com/cjneely10/MetaSanity/%s/VERSIONS.json" % \
                         versions[PACKAGE_VERSION]["metasanity_script"]
    subprocess.run(["wget", VERSIONS_JSON_FILE, "-O", "VERSIONS.json"], check=True)


@out_dir
def download_example_dataset():
    if os.path.exists("ExampleSet"):
        shutil.rmtree("ExampleSet")
    os.makedirs("ExampleSet")
    os.chdir("ExampleSet")
    for _id in ("TOBG-CPC-297", "TOBG-CPC-3", "TOBG-CPC-31", "TOBG-CPC-51", "TOBG-CPC-85", "TOBG-CPC-86",
                "TOBG-CPC-9", "TOBG-CPC-96", "TOBG-NP-99", "TOBG-NP-997"):
        subprocess.run(["wget",
                        "https://raw.githubusercontent.com/cjneely10/MetaSanity/%s/Example-Genomes-Set/%s.fna" %
                        (versions[PACKAGE_VERSION]["metasanity_script"], _id),
                        "-O", "%s.fna" % _id], check=True)


@out_dir
def download_accessory_script():
    if os.path.exists("Accessories"):
        shutil.rmtree("Accessories")
    os.makedirs("Accessories")
    os.chdir("Accessories")
    ACCESSORIES_URL_PRE = "https://raw.githubusercontent.com/cjneely10/MetaSanity/%s/Accessories/" % \
                          versions[PACKAGE_VERSION]["metasanity_script"]
    files_list = ["bowers_et_al_2017.py", "generate-typefile.py"]
    for _file in files_list:
        subprocess.run(["wget", ACCESSORIES_URL_PRE + _file, "-O", _file], check=True)


def docker_image():
    download_docker()


def scripts():
    config_pull()
    pull_download_script()
    download_metasanity()
    pull_versions_json_file()
    download_accessory_script()
    download_example_dataset()


def sourcecode():
    download_build_sourcecode()


def sourcecode_installation():
    sourcecode()
    subprocess.run(["pip3", "install", "BioMetaDB==%s" % versions[PACKAGE_VERSION]["biometadb"]])
    scripts()


def docker_installation():
    docker_image()
    subprocess.run(["pip3", "install", "BioMetaDB==%s" % versions[PACKAGE_VERSION]["biometadb"]])
    scripts()


if __name__ == "__main__":
    ap = ArgParse(
        (
            (("-s", "--sections"),
             {"help": "Comma-separated list to download.\nSelect from: docker_installation,sourcecode_installation,"
                      "docker_image,sourcecode,biometadb,scripts\n(def docker_installation)",
              "default": "docker_installation"}),
            (("-t", "--download_type"),
             {"help": "Download type for scripts. Select from: Docker,SourceCode (def Docker)", "default": "Docker"}),
            (("-v", "--version"),
             {"help": "Version to download. (def %s)" % DEFAULT_VERSION, "default": DEFAULT_VERSION})
        ),
        description="Download MetaSanity package"
    )

    assert ap.args.version in versions.keys(), "Invalid version, select from {}".format(",".join(versions.keys()))
    PACKAGE_VERSION = ap.args.version
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
