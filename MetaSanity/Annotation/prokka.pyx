# cython: language_level=3
import os
import luigi
import shutil
import subprocess
from MetaSanity.Accessories.ops import get_prefix
from MetaSanity.Parsers.tsv_parser import TSVParser
from MetaSanity.Parsers.fasta_parser import FastaParser
from MetaSanity.TaskClasses.luigi_task_class import LuigiTaskClass


class PROKKAConstants:
    PROKKA = "PROKKA"
    OUTPUT_DIRECTORY = "prokka_results"
    AMENDED_RESULTS_SUFFIX = ".prk.tsv.amd"
    STORAGE_STRING = "prokka results"
    FINAL_RESULTS_SUFFIX = ".prk-to-prd.tsv"


class PROKKA(LuigiTaskClass):
    output_directory = luigi.Parameter()
    out_prefix = luigi.Parameter()
    fasta_file = luigi.Parameter()
    domain_type = luigi.Parameter(default="Bacteria")

    def requires(self):
        return []

    def run(self):
        print("Running PROKKA..........")
        if not os.path.exists(str(self.output_directory)):
            os.makedirs(str(self.output_directory))
        cdef str outfile_prefix = get_prefix(str(self.fasta_file))
        if not os.path.isfile(os.path.join(str(self.output_directory), outfile_prefix, outfile_prefix + ".tsv")):
            subprocess.run(
                [
                    str(self.calling_script_path),
                    "--prefix",
                    str(self.out_prefix),
                    "--kingdom",
                    "%s%s" % (str(self.domain_type)[0].upper(), str(self.domain_type)[1:]),
                    "--outdir",
                    os.path.join(str(self.output_directory), outfile_prefix),
                    str(self.fasta_file),
                    *self.added_flags,
                ],
                check=True,
            )
        write_prokka_amended(
            os.path.join(str(self.output_directory), outfile_prefix, outfile_prefix + ".tsv"),
            os.path.join(str(self.output_directory), outfile_prefix, outfile_prefix + PROKKAConstants.AMENDED_RESULTS_SUFFIX)
        )
        shutil.move(
            os.path.join(str(self.output_directory), outfile_prefix, outfile_prefix + ".faa"),
            os.path.join(str(self.output_directory), outfile_prefix, outfile_prefix + ".fxa")
        )
        FastaParser.write_simple(
            os.path.join(str(self.output_directory), outfile_prefix, outfile_prefix + ".fxa"),
            os.path.join(str(self.output_directory), outfile_prefix, outfile_prefix + ".faa"),
            simplify=outfile_prefix,
        )
        print("PROKKA complete!")

    def output(self):
        return luigi.LocalTarget(
            os.path.join(str(self.output_directory),
                         get_prefix(str(self.fasta_file)),
                         get_prefix(str(self.fasta_file)) + PROKKAConstants.AMENDED_RESULTS_SUFFIX)
        )


class PROKKAMatcher(LuigiTaskClass):
    output_directory = luigi.Parameter()
    outfile = luigi.Parameter()
    diamond_file = luigi.Parameter()
    prokka_tsv = luigi.Parameter()
    suffix = luigi.Parameter(default="")
    evalue = luigi.Parameter()
    pident = luigi.Parameter()
    matches_file = luigi.Parameter()

    def requires(self):
        pass

    def run(self):
        print("Running PROKKAMatcher..........")
        if os.path.exists(str(self.diamond_file)):
            match_prokka_to_prodigal_and_write_tsv(
                str(self.diamond_file),
                str(self.prokka_tsv),
                str(self.matches_file),
                os.path.join(str(self.output_directory), str(self.outfile)),
                float(str(self.evalue)),
                float(str(self.pident)),
                0,
                1,
                4,
                5,
                suffix=str(self.suffix),
            )
        print("PROKKAMatcher complete!")

    def output(self):
        return luigi.LocalTarget(os.path.join(os.path.join(str(self.output_directory), str(self.outfile))))


cdef void write_prokka_amended(str prokka_results, str outfile):
    """ Shortens output from prokka to only be CDS identifiers
    
    :param prokka_results: 
    :param outfile: 
    :return: 
    """
    cdef object tsvParser = TSVParser(prokka_results)
    # Call through object to retain header line
    tsvParser.read_file(header_line=True)
    cdef list prokka_data = tsvParser.get_values()
    cdef object W = open(outfile, "w")
    cdef list prokka_inner_list
    cdef str val, out_string = ""
    if prokka_data:
        # Write Header
        W.write(tsvParser.header())
        W.write("\n")
        for prokka_inner_list in prokka_data:
            if prokka_inner_list[1] == "CDS":
                for val in prokka_inner_list:
                    out_string += val + "\t"
                W.write(out_string[:-1])
                W.write("\n")
                out_string = ""
        W.close()


cdef void match_prokka_to_prodigal_and_write_tsv(str diamond_file, str prokka_annotation_tsv, str matches_file, str outfile,
                                                 float evalue = 1e-10, float pident = 98.5, int qcol = 0, int scol = 1,
                                                 int pident_col = 4, int evalue_col = 5, str suffix = ""):
    """ Function uses the output from diamond to identify highest matches between prodigal and prokka via evalue and pident.
    If a match, will write to .tsv file the prokka annotation named as the prodigal gene call 
    
    :param diamond_file: 
    :param prokka_annotation_tsv: 
    :param matches_file: 
    :param outfile: 
    :param evalue: 
    :param pident:
    :param qcol:
    :param scol:
    :param pident_col:
    :param evalue_col:
    :param suffix:
    :return: 
    """
    cdef dict matches = {}
    cdef object W = open(outfile, "w")
    cdef dict prokka_data = TSVParser.parse_dict(prokka_annotation_tsv)
    W.write("ID\tprokka\n")
    cdef bytes _line
    cdef list line
    cdef object R = open(diamond_file, "rb")
    cdef str _id
    cdef dict highest_matches = {}
    cdef tuple best_match
    cdef str prokka_out_string
    for _line in open(matches_file, "rb"):
        line = _line.decode().rstrip("\r\n").split("\t")
        matches[line[0]] = line[1]
    for _line in R:
        line = _line.decode().rstrip("\r\n").split("\t")
        best_match = highest_matches.get(line[qcol], None)
        if float(line[pident_col]) >= pident and float(line[evalue_col]) <= evalue and \
                (best_match is None or (best_match[2] > float(line[pident_col]) and best_match[3] < float(line[evalue_col]))):
            highest_matches[line[qcol]] = (line[scol], line[qcol], float(line[pident_col]), float(line[evalue_col]))
    for best_match in highest_matches.values():
        if prokka_data[best_match[0]][2] != "":
            # prokka_out_string = "%s-%s:::%s;;;" % (*(best_match[1].split("-")[-1].split("_")), prokka_data[best_match[0]][2])
            W.write(matches[best_match[1]] + suffix + "\t" + prokka_data[best_match[0]][2] + "\n")
    W.close()
    R.close()

