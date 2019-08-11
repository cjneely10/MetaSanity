# cython: language_level=3

import luigi
import os


class LuigiTaskClass(luigi.Task):
    fasta_folder = luigi.Parameter(default="None")
    calling_script_path = luigi.Parameter()
    added_flags = luigi.ListParameter(default=[])
    output_directory = luigi.Parameter(default="outdir")
    outfile = luigi.Parameter(default="out")

    def output(self):
        return luigi.LocalTarget(str(self.output_directory)), \
               luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.outfile)))
