# cython: language_level=3

import os
import luigi
from MetaSanity.Parsers.fasta_parser import FastaParser


class SplitFileConstants:
    OUTPUT_DIRECTORY = "splitfiles"


class SplitFile(luigi.Task):
    fasta_file = luigi.Parameter()
    out_dir = luigi.Parameter()

    def run(self):
        if not os.path.isdir(str(self.out_dir)):
            os.makedirs(str(self.out_dir))
        FastaParser.split(str(self.fasta_file), out_dir=str(self.out_dir))

    def output(self):
        pass

    def requires(self):
        return []
