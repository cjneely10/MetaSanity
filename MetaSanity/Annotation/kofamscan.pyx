# cython: language_level=3
import luigi
import os
import shutil
import subprocess
from MetaSanity.TaskClasses.luigi_task_class import LuigiTaskClass
from MetaSanity.Annotation.FunctionalProfileReader.reader import KoFamScan


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
        cdef str outfile_path = os.path.join(str(self.output_directory), str(self.outfile) + ".tmp.tsv")
        cdef str outpath = os.path.join(str(self.output_directory), str(self.outfile) + ".tsv")
        cdef str tmp_path = os.path.join(str(self.output_directory), KofamScanConstants.TMP_DIR)
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
        # for biodata
        KoFamScan.write_highest_matches(
            outfile_path,
            outpath
        )
        if os.path.getsize(outpath) != 0:
            # for dbdm
            KoFamScan.write_highest_matches(
                outfile_path,
                os.path.splitext(outpath)[0] + KofamScanConstants.AMENDED_RESULTS_SUFFIX,
                ".faa",
                "ID\tKO"
            )
        else:
            os.remove(outpath)
        # Remove temp directory and file
        os.remove(outfile_path)
        shutil.rmtree(tmp_path)
        print("KofamScan complete!")

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.outfile) + KofamScanConstants.AMENDED_RESULTS_SUFFIX))
