#!/usr/bin/env python3
import os
import shutil
import argparse
import subprocess
from argparse import RawTextHelpFormatter

AVAILABLE_DATABASES = "gtdbtk,checkm,kofamscan,peptidase,virsorter"


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


def make_dirs(_dir):
    """ Decorator function creates needed data download directories

    :param _dir:
    :return:
    """
    def decorator(func):
        def func_wrapper(outdir, *args, **kwargs):
            current_loc = os.getcwd()
            outdir = os.path.join(os.path.abspath(outdir), _dir)
            if not os.path.exists(outdir):
                os.makedirs(outdir)
            os.chdir(outdir)
            func(outdir, *args, **kwargs)
            os.chdir(current_loc)

        return func_wrapper

    return decorator


def wget(url, tar=False, gzip=False):
    """ Function downloads a given url and decompresses it as needed

    :param url:
    :param tar:
    :param gzip:
    :return:
    """
    assert not (tar and gzip), "Only tar or gzip allowed"
    subprocess.run(["wget", url], check=True)
    if tar:
        subprocess.run(["tar", "-xzf", os.path.basename(url)], check=True)
        os.remove(os.path.basename(url))
    elif gzip:
        subprocess.run(["gunzip", os.path.basename(url)], check=True)


@make_dirs("gtdbtk")
def gtdbtk(outdir, *args, **kwargs):
    RELEASE_URL = "https://data.ace.uq.edu.au/public/gtdb/data/releases/release89/89.0/gtdbtk_r89_data.tar.gz"
    wget(RELEASE_URL, tar=True)


@make_dirs("checkm")
def checkm(outdir, *args, **kwargs):
    RELEASE_URL = "https://data.ace.uq.edu.au/public/CheckM_databases/checkm_data_2015_01_16.tar.gz"
    wget(RELEASE_URL, tar=True)


@make_dirs("kofamscan")
def kofamscan(outdir, *args, **kwargs):
    PROFILES_URL = "ftp://ftp.genome.jp/pub/db/kofam/profiles.tar.gz"
    wget(PROFILES_URL, tar=True)
    KO_LIST_URL = "ftp://ftp.genome.jp/pub/db/kofam/ko_list.gz"
    wget(KO_LIST_URL, gzip=True)


@make_dirs("peptidase")
def peptidase(outdir, *args, **kwargs):
    # DBCAN_URL = "url"
    # wget(DBCAN_URL)
    # os.remove(os.path.basename(DBCAN_URL))
    MEROPS_URL = "https://www.dropbox.com/s/8pskp3hlkdnt6zm/MEROPS.pfam.hmm?dl=1"
    wget(MEROPS_URL)
    shutil.move(os.path.basename(MEROPS_URL), os.path.basename(MEROPS_URL)[:-5])
    MEROPS_AS_PFAMS_URL = "https://raw.githubusercontent.com/cjneely10/MetaSanity/master/Sample/Data/merops-as-pfams" \
                          ".txt"
    wget(MEROPS_AS_PFAMS_URL)


@make_dirs("virsorter")
def virsorter(outdir, *args, **kwargs):
    RELEASE_URL = "https://zenodo.org/record/1168727/files/virsorter-data-v2.tar.gz"
    wget(RELEASE_URL, tar=True)


if __name__ == "__main__":
    ap = ArgParse(
        ((("-d", "--data"),
          {"help": "Comma-separated list (no spaces) of databases to download, default all", "default": "all"}),
         (("-o", "--outdir"),
          {"help": "Directory for storing database files, default 'databases'", "default": "databases"}),),
        description="Download required BioMetaPipeline data\nSelect from: %s" % AVAILABLE_DATABASES)

    if ap.args.data == "all":
        to_download = AVAILABLE_DATABASES.split(",")
    else:
        to_download = [val.lower() for val in ap.args.data.split(",") if val != ""]
    for dwnld in to_download:
        try:
            locals()[dwnld](ap.args.outdir)
        except KeyError:
            print("%s database not found" % dwnld)
