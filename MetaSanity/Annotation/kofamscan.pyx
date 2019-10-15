# cython: language_level=3
import luigi
import os
import subprocess
from MetaSanity.TaskClasses.luigi_task_class import LuigiTaskClass


class KofamScanConstants:
    KOFAMSCAN = "KOFAMSCAN"
    OUTPUT_DIRECTORY = "kofamscan_results"
    TMP_DIR = "_tmp_"
    AMENDED_RESULTS_SUFFIX = ".amended.tbl"
    KEGG_DIRECTORY = "kegg_results"
    STORAGE_STRING = "kofamscan results"

class KofamScan(LuigiTaskClass):
    output_directory = luigi.Parameter()
    outfile = luigi.Parameter()
    fasta_file = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        print("Running KofamScan..........")
        if not os.path.exists(str(self.output_directory)):
            os.makedirs(str(self.output_directory))
        cdef str outfile_path = os.path.join(str(self.output_directory), str(self.outfile) + ".detailed")
        cdef str outpath = os.path.join(str(self.output_directory), str(self.outfile) + ".tsv")
        cdef str tmp_path = os.path.join(str(self.output_directory), KofamScanConstants.TMP_DIR)
        cdef str _id
        cdef tuple data
        subprocess.run(
            [
                str(self.calling_script_path),
                "-o",
                outfile_path,
                "--tmp-dir",
                tmp_path,
                *self.added_flags,
                str(self.fasta_file),
            ],
            check=True,
        )
        W_biodata = open(outpath, "w")
        W_biometadb = open(os.path.splitext(outpath)[0] + KofamScanConstants.AMENDED_RESULTS_SUFFIX, "w")
        matches_data = get_matches_data(outfile_path)
        W_biometadb.write("ID\tKO\n")
        for _id, data in matches_data.items():
            # for BioData
            W_biodata.write(_id + "\t" + data[0] + "\n")
            # for BioMetaDB
            W_biometadb.write(_id + ".faa" + "\t" + data[0] + " " + data[1] + "\n")
        W_biodata.close()
        W_biometadb.close()
        print("KofamScan complete!")

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), os.path.splitext(str(self.outfile))[0] + KofamScanConstants.AMENDED_RESULTS_SUFFIX))


def get_matches_data(str kofamscan_file):
    """ Parses kofamscan details file and gathers highest match for each gene call, which is first in list

    :param kofamscan_file:
    :return:
    """
    kegg_data = {}
    cdef str _line
    cdef list line
    with open(kofamscan_file, "r") as R:
        # Skip over header
        next(R)
        next(R)
        for _line in R:
            line = _line.rstrip("\r\n").split()
            if line[0] == '*':
                match = kegg_data.get(line[1], None)
                if match is None:
                    kegg_data[line[1]] = (line[2], " ".join(line[6:]))
    return kegg_data
