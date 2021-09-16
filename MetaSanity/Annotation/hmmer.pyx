# cython: language_level=3
import os
import luigi
import shutil
import subprocess
from sys import stderr
from MetaSanity.TaskClasses.luigi_task_class import LuigiTaskClass


class HMMSearchConstants:
    HMMSEARCH = "HMMSEARCH"
    OUTPUT_DIRECTORY = "hmmsearch_results"


class HMMSearch(LuigiTaskClass):
    output_directory = luigi.Parameter()
    out_file = luigi.Parameter()
    fasta_file = luigi.Parameter()
    hmm_file = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        print("Running HMMSearch..........")
        if not os.path.exists(str(self.output_directory)):
            os.makedirs(str(self.output_directory))
        W = open(os.path.join(str(self.output_directory), str(self.out_file) + ".log"), "w")
        subprocess.run(
            [
                str(self.calling_script_path),
                "--tblout",
                os.path.join(str(self.output_directory), str(self.out_file)),
                *self.added_flags,
                str(self.hmm_file),
                str(self.fasta_file),
            ],
            check=True,
            stdout=W
        )
        W.close()
        print("HMMSearch complete!")

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.out_file)))


class HMMConvertConstants:
    HMMCONVERT = "HMMCONVERT"
    OUTPUT_DIRECTORY  = "hmmconvert_data"


class HMMConvert(LuigiTaskClass):
    output_directory = luigi.Parameter()
    hmm_file = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        print("Running HMMConvert..........")
        if not os.path.exists(str(self.output_directory)):
            os.makedirs(str(self.output_directory))
        cdef object outfile = open(os.path.join(str(self.output_directory), os.path.basename(str(self.hmm_file))), "w")
        subprocess.run(
            [
                str(self.calling_script_path),
                str(self.hmm_file),
                *self.added_flags,
            ],
            check=True,
            stdout=outfile,
        )
        outfile.close()
        print("HMMConvert complete!")

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), os.path.basename(str(self.hmm_file))))


class HMMPressConstants:
    HMMPRESS = "HMMPRESS"
    OUTPUT_DIRECTORY  = HMMConvertConstants.OUTPUT_DIRECTORY


class HMMPress(LuigiTaskClass):
    output_directory = luigi.Parameter()
    hmm_file = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        print("Running HMMPress..........")
        # Move hmm file to output directory
        if not os.path.exists(str(self.output_directory)):
            os.makedirs(str(self.output_directory))
        cdef str moved_hmmfile = os.path.join(str(self.output_directory), os.path.basename(str(self.hmm_file)))
        shutil.copy(str(self.hmm_file), moved_hmmfile)
        subprocess.run(
            [
                str(self.calling_script_path),
                "-f",
                moved_hmmfile,
                *self.added_flags,
            ],
            check=True,
            stdout=stderr,
        )
        print("HMMPress complete!")

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), os.path.basename(str(self.hmm_file))) + ".h3p")
