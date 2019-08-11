# distutils: language = c++
import os
import luigi
from collections import Counter
from libcpp.string cimport string
from libcpp.vector cimport vector
from MetaSanity.TaskClasses.luigi_task_class import LuigiTaskClass


cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


class CAZYConstants:
    CAZY = "CAZY"
    OUTPUT_DIRECTORY = "cazy"
    HMM_FILE = "cazy_hmm.list"
    ASSIGNMENTS = "cazy_assignments.tsv"
    ASSIGNMENTS_BY_PROTEIN = "cazy_assignments.byprot.tsv"
    STORAGE_STRING = "CAZy results"
    SUMMARY_STORAGE_STRING = "summary CAZy results"


class CAZY(LuigiTaskClass):
    hmm_results = luigi.Parameter()
    output_directory = luigi.Parameter()
    outfile = luigi.Parameter()
    prot_suffix = luigi.Parameter()
    genome_basename = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        print("Running CAZy search..........")
        if not os.path.exists(str(self.output_directory)):
            os.makedirs(str(self.output_directory))
        cdef string genome, cazy, val
        cdef int count
        cdef string prot_suffix = <string>PyUnicode_AsUTF8(str(self.prot_suffix))
        cdef vector[string] _cazy_ids
        cdef object W
        cdef object WP
        # Populate vector _cazy_ids by reference
        cdef dict cazy_data = create_cazy_dict(_cazy_ids, str(self.hmm_results))
        cdef dict count_data = <dict>Counter([val for val in (<dict>cazy_data).values()])
        # Set of no-repeated cazy ids
        cdef set cazy_ids = set([cazy for cazy in _cazy_ids])
        # Write compiled count data
        if cazy_ids and count_data and cazy_data:
            W = open(os.path.join(str(self.output_directory), str(self.outfile)), "wb")
            WP = open(
                os.path.join(str(self.output_directory),
                             str(self.outfile).replace(CAZYConstants.ASSIGNMENTS, CAZYConstants.ASSIGNMENTS_BY_PROTEIN)),
                "wb"
            )
            W.write(<string>"ID")
            for cazy in cazy_ids:
                W.write(<string>"\t" + cazy)
            W.write(<string>"\n")
            W.write(<string>PyUnicode_AsUTF8(str(self.genome_basename)))
            for cazy in cazy_ids:
                val = <string>PyUnicode_AsUTF8(str(count_data.get(cazy, 0)))
                W.write(<string>"\t" + val)
            W.write(<string>"\n")
            # Write individual protein data
            WP.write(<string>"ID\tCAZy\n")
            for genome, cazy in cazy_data.items():
                WP.write(genome + prot_suffix + <string>"\t" + cazy + <string>"\n")
            W.close()
            WP.close()
        print("CAZy search complete!")

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.outfile)))


cdef dict create_cazy_dict(vector[string]& cazy_ids, str file_name):
    """ Function fills vector parameter cazy_ids with list of cazy hmm ids. Data gathered by protein id, removing
    .hmm extension from query name
    
    :param cazy_ids: 
    :param file_name: 
    :param suffix: 
    :return: 
    """
    cdef object R = open(file_name, "rb")
    cdef list line
    cdef string comment_header = "#"
    cdef bytes _line
    cdef int val
    cdef string _id, cazy, _cazy
    cdef dict cazy_dict = {}
    for _line in R:
        if _line.startswith(bytes(comment_header)):
            continue
        # File is delimited by unknown number of spaces
        line = _line.decode().rstrip("\r\n").split(maxsplit=3)
        # Store id in vector
        _cazy = <string>PyUnicode_AsUTF8(line[2])
        cazy = _cazy.substr(0, _cazy.size() - 4)
        cazy_ids.push_back(cazy)
        _id = <string>PyUnicode_AsUTF8(line[0])
        cazy_dict[_id] = cazy
    R.close()
    return cazy_dict
