# cython: language_level=3
import os
import luigi
from MetaSanity.Parsers.fasta_parser import FastaParser
from MetaSanity.TaskClasses.luigi_task_class import LuigiTaskClass


cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


class MEROPSConstants:
    MEROPS = "MEROPS"
    OUTPUT_DIRECTORY = "merops"
    HMM_FILE = "merops_hmm.list"
    MEROPS_PROTEIN_FILE_SUFFIX = "merops.protein.faa"
    STORAGE_STRING = "MEROPS results"
    SUMMARY_STORAGE_STRING = "MEROPS pfam results"


class MEROPS(LuigiTaskClass):
    hmm_results = luigi.Parameter()
    output_directory = luigi.Parameter()
    outfile = luigi.Parameter()
    prot_file = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        print("Running MEROPS search..........")
        if not os.path.exists(str(self.output_directory)):
            os.makedirs(str(self.output_directory))
        # Gather MEROPS gene ids
        cdef set match_ids = set()
        cdef object R = open(str(self.hmm_results), "r")
        cdef str _line, _id
        cdef str delimiter = "#"
        cdef list line
        for _line in R:
            line = _line.split(maxsplit=1)
            if delimiter not in line[0]:
                match_ids.add(line[0])
        R.close()
        # Write protein sequences that match MEROPS genes
        cdef str out_file = os.path.join(str(self.output_directory), str(self.outfile))
        if os.path.exists(str(self.prot_file)) and os.path.getsize(str(self.prot_file)) != 0:
            FastaParser.write_records(str(self.prot_file), list(match_ids), out_file, filter_func)
        print("MEROPS search complete!")

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.outfile)))


def filter_func(str _id):
    """ Generic filtering of simplified file ids

    :param _id:
    :return:
    """
    return int(_id.split("_")[-1])


def build_merops_dict(str file_name):
    """ Function builds dict of merops values. Must be str per luigi documentation
    
    :param file_name: 
    :return: 
    """
    cdef str _line
    cdef list line
    cdef dict merops_data = {}
    cdef object merops_file = open(file_name, "r")
    # Skip header
    next(merops_file)
    for _line in merops_file:
        line = _line.rstrip("\r\n").split("\t")
        merops_data[line[3]] = "%s.%s" % (line[0], line[1])
    return merops_data
