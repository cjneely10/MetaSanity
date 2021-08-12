# cython: language_level=3
import os
import luigi
import shutil
import subprocess
from sys import stderr
from MetaSanity.Accessories.ops import get_prefix
from MetaSanity.TaskClasses.luigi_task_class import LuigiTaskClass
from MetaSanity.Parsers.virsorter_parser cimport parse_virsorter_to_dbdm_tsv


class VirSorterConstants:
    VIRSORTER = "VIRSORTER"
    OUTPUT_DIRECTORY = "virsorter_results"
    DEFAULT_CSV_OUTFILE = "VIRSorter_global-phage-signal.csv"
    ADJ_OUT_FILE = "VIRSorter_adj_out.tsv"
    STORAGE_STRING = "virsorter results"


class VirSorter(LuigiTaskClass):
    fasta_file = luigi.Parameter()
    wdir = luigi.Parameter()
    is_docker = luigi.BoolParameter()

    def requires(self):
        return []

    def run(self):
        print("Running VirSorter..........")
        if not os.path.exists(str(self.wdir)):
            os.makedirs(str(self.wdir))
        shutil.copy(str(self.fasta_file), str(self.wdir))
        cdef int index_of_user = self.added_flags.index("--user") if "--user" in self.added_flags else -1
        cdef list username = []
        cdef list ending_flags = list(self.added_flags)
        if index_of_user != -1:
            username = ["--user", self.added_flags[index_of_user + 1]]
            del ending_flags[index_of_user + 1]
            del ending_flags[index_of_user]
        if self.is_docker:
            # if not os.path.exists(os.path.join(str(self.wdir), "virsorter-out")):
            #     os.makedirs(os.path.join(str(self.wdir), "virsorter-out"))
            self.try_local(ending_flags)
        else:
            try:
                self.try_local(ending_flags)
            except:
                self.try_docker(ending_flags, username)
        if not os.listdir(str(self.wdir)):
            os.rmdir(str(self.wdir))
        print("VirSorter complete!")

    def output(self):
        pass
        if os.path.exists(str(self.wdir)):
            return luigi.LocalTarget(os.path.join(str(self.wdir), "virsorter-out", get_prefix(str(self.fasta_file)) + "." + VirSorterConstants.ADJ_OUT_FILE))

    def try_docker(self, list ending_flags, list username):
        if not os.path.exists(os.path.join(str(self.wdir), "virsorter-out", VirSorterConstants.DEFAULT_CSV_OUTFILE)):
            subprocess.run(
                [
                    "docker",
                    "run",
                    *username,
                    "-v",
                    "%s:/data" % str(self.calling_script_path),
                    "-v",
                    "%s:/wdir" % str(self.wdir),
                    "-w",
                    "/wdir",
                    "--rm",
                    "simroux/virsorter:v1.0.5",
                    "--fna",
                    os.path.basename(str(self.fasta_file)),
                    *ending_flags,
                ],
                check=True,
                stdout=stderr,
            )
        parse_virsorter_to_dbdm_tsv(
            os.path.join(str(self.wdir), "virsorter-out", VirSorterConstants.DEFAULT_CSV_OUTFILE),
            str(self.fasta_file),
            os.path.join(str(self.wdir), "virsorter-out",
                         get_prefix(str(self.fasta_file)) + "." + VirSorterConstants.ADJ_OUT_FILE)
        )
        os.remove(os.path.join(str(self.wdir), os.path.basename(str(self.fasta_file))))

    def try_local(self, list ending_flags):
        if not os.path.exists(os.path.join(str(self.wdir), "virsorter-out", VirSorterConstants.DEFAULT_CSV_OUTFILE)):
            try:
                subprocess.run(
                    [
                        "virsorter",
                        "--fna",
                        str(self.fasta_file),
                        "--data-dir",
                        str(self.calling_script_path),
                        "--wdir",
                        os.path.join(str(self.wdir), "virsorter-out"),
                        *ending_flags,
                    ],
                    check=True,
                    stdout=stderr,
                )
            except:
                subprocess.run(
                    [
                        "virsorter",
                        "run", "all",
                        "-i",
                        str(self.fasta_file),
                        "-w",
                        os.path.join(str(self.wdir), "virsorter-out"),
                        *ending_flags,
                    ],
                    check=True,
                    stdout=stderr,
                )
        parse_virsorter_to_dbdm_tsv(
            os.path.join(str(self.wdir), "virsorter-out", VirSorterConstants.DEFAULT_CSV_OUTFILE),
            str(self.fasta_file),
            os.path.join(str(self.wdir), "virsorter-out",
                         get_prefix(str(self.fasta_file)) + "." + VirSorterConstants.ADJ_OUT_FILE)
        )
        os.remove(os.path.join(str(self.wdir), os.path.basename(str(self.fasta_file))))
