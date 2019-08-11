# cython: language_level=3
import luigi
import os
import subprocess
from MetaSanity.TaskClasses.luigi_task_class import LuigiTaskClass


class FastANIConstants:
    FASTANI = "FASTANI"
    OUTPUT_DIRECTORY = "fastani_results"
    OUTFILE = "fastani_results.txt"


class FastANI(LuigiTaskClass):
    outfile = luigi.Parameter(default=FastANIConstants.OUTFILE)
    output_directory = luigi.Parameter()
    listfile_of_fasta_with_paths = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        print("Beginning FastANI..........")
        if not os.path.exists(str(self.output_directory)):
            os.makedirs(str(self.output_directory))
        subprocess.run(
            [str(self.calling_script_path),
             *self.added_flags,
             "--ql",
             str(self.listfile_of_fasta_with_paths),
             "--rl",
             str(self.listfile_of_fasta_with_paths),
             "-o",
             os.path.join(str(self.output_directory), str(self.outfile))],
            check=True,
        )
        print("FastANI complete")
