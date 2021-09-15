# cython: language_level=3
import os
import luigi
import shutil
import subprocess
from MetaSanity.Accessories.ops import get_prefix
from MetaSanity.FileOperations.split_file import SplitFileConstants
from MetaSanity.Parsers.fasta_parser import FastaParser
from MetaSanity.TaskClasses.luigi_task_class import LuigiTaskClass


class PROKKAConstants:
    PROKKA = "PROKKA"
    OUTPUT_DIRECTORY = "prokka_results"
    OUT_ADDED = ".prokka.nucl"
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
        # Write amended TSV file for only CDS, tRNA, and rRNA entries
        write_prokka_amended(
            os.path.join(str(self.output_directory), outfile_prefix, outfile_prefix + ".tsv"),
            os.path.join(str(self.output_directory), outfile_prefix, outfile_prefix + PROKKAConstants.AMENDED_RESULTS_SUFFIX),
            os.path.join(str(self.output_directory), outfile_prefix, outfile_prefix + ".ffn"),
            os.path.join(os.path.dirname(str(self.output_directory)), SplitFileConstants.OUTPUT_DIRECTORY, outfile_prefix),
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
            os.path.join(str(self.output_directory), str(self.out_prefix), str(self.out_prefix) + ".tsv")
        )


class PROKKAMatcher(luigi.Task):
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


cdef void write_prokka_amended(str prokka_results, str outfile, str prokka_nucl_fasta, str prokka_nucl_out_folder):
    """ Shortens output from prokka to only be CDS identifiers. rRNA and tRNA are parsed to separate tsv,
    and the fasta records are written to their own directory
    
    :param prokka_results: 
    :param outfile: 
    :param prokka_nucl_fasta: 
    :param prokka_nucl_out_folder: 
    :return: 
    """
    if not os.path.exists(prokka_nucl_out_folder):
        os.makedirs(prokka_nucl_out_folder)
    R = open(prokka_results, "rb")
    W = open(outfile, "wb")
    cdef str out_added = os.path.splitext(outfile)[0] + PROKKAConstants.OUT_ADDED
    W_added = open(out_added, "wb")
    cdef bint has_added = False
    cdef bytes _line
    cdef list line
    # Accumulate t/rRNA data and store fasta results to separate directory and tsv file
    cdef tuple added = (b"tRNA", b"rRNA")
    cdef dict prokka_nucl_dict = FastaParser.parse_dict(prokka_nucl_fasta, is_python=False)
    # Skip over header
    next(R)
    W.write(b"ID\tprokka\n")
    W_added.write(b"ID\tprokka\n")
    for _line in R:
        line = _line.rstrip(b"\r\n").split()
        # CDS match
        if line[1] == b"CDS":
            # Write line from gene identifier to end of line
            W.write(line[0] + b"\t")
            W.write(b" ".join(line[3:]))
            W.write(b"\n")
        # rRNA or tRNA match
        elif line[1] in added:
            has_added = True
            W_added.write(line[0] + b".fna" + b"\t")
            W_added.write(b" ".join(line[3:]))
            W_added.write(b"\n")
            out_fasta = open(os.path.join(prokka_nucl_out_folder, "".join([chr(_c) for _c in line[0] + b".fna"])), "wb")
            record = prokka_nucl_dict.get(line[0], None)
            record = (
                line[0],
                b"",
                record[1]
            )
            out_fasta.write(FastaParser.record_to_string(record))
    if not has_added:
        os.remove(out_added)
    W_added.close()
    W.close()


cdef void match_prokka_to_prodigal_and_write_tsv(str diamond_file, str prokka_annotation_tsv, str matches_file, str outfile,
                                                 float evalue, float pident, int qcol = 0, int scol = 1,
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
    cdef str _l, val
    cdef list line
    cdef tuple match
    cdef dict highest_matches = {}
    W = open(outfile, "w")
    # Read in contig segment to protein data
    contig_to_proteins = _read_in_file(matches_file)
    # Read in prokka data
    prokka_data = _read_in_file(prokka_annotation_tsv)
    # Get highest matching prokka contig id for each contig
    with open(diamond_file, "r") as R:
        for _l in R:
            line = _l.rstrip("\r\n").split("\t")
            match = highest_matches.get(line[qcol], None)
            if float(line[pident_col]) >= pident and float(line[evalue_col]) <= evalue and \
                    (match is None or (match[2] > float(line[pident_col]) and match[3] < float(line[evalue_col]))):
                highest_matches[line[qcol]] = (line[scol], line[qcol], float(line[pident_col]), float(line[evalue_col]))
    # Write best matches as id\tannotation\n
    W.write("ID\tprokka\n")
    for match in highest_matches.values():
        val = contig_to_proteins.get(match[1], None)
        if val is not None:
            W.write(val + suffix + "\t" + prokka_data[match[0]] + "\n")
    W.close()


def _read_in_file(str _file):
    """ Convert file to simple key\tvalue\n dict

    :param _file:
    :return:
    """
    cdef str _line
    cdef list line
    out_dict = {}
    with open(_file, "r") as R:
        for _line in R:
            line = _line.rstrip("\r\n").split("\t")
            out_dict[line[0]] = line[1]
    return out_dict
