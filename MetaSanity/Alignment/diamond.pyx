# cython: language_level=3
import os
import luigi
import subprocess
from sys import stderr
from MetaSanity.Accessories.ops import get_prefix
from MetaSanity.Parsers.blast_to_fasta import blast_to_fasta
from MetaSanity.TaskClasses.luigi_task_class import LuigiTaskClass


class DiamondConstants:
    DIAMOND = "DIAMOND"
    OUTPUT_DIRECTORY = "diamond"


class Diamond(LuigiTaskClass):
    outfile = luigi.Parameter()
    output_directory = luigi.Parameter()
    program = luigi.Parameter(default="blastx")
    diamond_db = luigi.Parameter()
    query_file = luigi.Parameter()
    evalue = luigi.Parameter(default="1e-15")

    def run(self):
        assert str(self.program) in {"blastx", "blastp"}, "Invalid program passed"
        cdef str status = "Running Diamond.........."
        print(status)
        cdef tuple outfmt = ("--outfmt", "6", "qseqid", "sseqid", "qstart", "qend", "pident", "evalue")
        if os.path.exists(str(self.diamond_db) + ".dmnd"):
            subprocess.run(
                [
                    str(self.calling_script_path),
                    str(self.program),
                    "--tmpdir",
                    "/dev/shm",
                    "-d",
                    str(self.diamond_db),
                    "-q",
                    str(self.query_file),
                    "-o",
                    os.path.join(str(self.output_directory), str(self.outfile)),
                    *outfmt,
                    "--evalue",
                    str(self.evalue),
                    *self.added_flags
                ],
                check=True,
                stdout=stderr,
            )
        print("%s%s" % (status[:-5],"done!"))

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.outfile)))


class DiamondMakeDB(LuigiTaskClass):
    output_directory = luigi.Parameter()
    prot_file = luigi.Parameter()

    def run(self):
        print("Running Diamond makedb..........")
        if not os.path.exists(str(self.output_directory)):
            os.makedirs(str(self.output_directory))
        if os.path.getsize(str(self.prot_file)) != 0:
            subprocess.run(
                [
                    str(self.calling_script_path),
                    "makedb",
                    "--tmpdir",
                    "/dev/shm",
                    "--in",
                    str(self.prot_file),
                    "-d",
                    os.path.join(str(self.output_directory), get_prefix(str(self.prot_file))),
                ],
                check=True,
                stdout=stderr,
            )
        print("Diamond makedb complete!")

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), get_prefix(str(self.prot_file)) + ".dmnd"))


class DiamondToFasta(LuigiTaskClass):
    output_directory = luigi.Parameter()
    outfile = luigi.Parameter()
    fasta_file = luigi.Parameter()
    diamond_file = luigi.Parameter()
    evalue = luigi.Parameter(default="1e-15")

    def run(self):
        print("Running DiamondToFasta..........")
        if not os.path.exists(str(self.output_directory)):
            os.makedirs(str(self.output_directory))
        if os.path.getsize(str(self.fasta_file)) != 0 and os.path.exists(str(self.diamond_file)):
            blast_to_fasta(
                str(self.fasta_file),
                str(self.diamond_file),
                os.path.join(str(self.output_directory), str(self.outfile)),
                e_value=float(str(self.evalue)),
            )
        print("DiamondToFasta complete!")


    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.outfile)))
