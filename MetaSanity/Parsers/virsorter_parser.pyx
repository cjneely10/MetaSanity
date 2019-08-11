# distutils: language = c++
import os
from libcpp.string cimport string
from MetaSanity.Parsers.fasta_parser import FastaParser


cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


cdef void parse_virsorter_to_dbdm_tsv(str virsorter_file, str fasta_file, str outfile):
    """ Rewrites prokka file 
    
    :param virsorter_file: 
    :param fasta_file: 
    :param outfile: 
    :return: 
    """
    cdef dict vir_cats = {
        "1": "num_phage_contigs_1",
        "2": "num_phage_contigs_2",
        "3": "num_phage_contigs_3",
        "4": "num_prophages_1",
        "5": "num_prophages_2",
        "6": "num_prophages_3"
    }
    cdef object P = open(virsorter_file, "rb")
    cdef object W
    cdef list line
    cdef bytes _l
    cdef string delim = "##"
    cdef string _line, _dat
    cdef dict data_dict = {}, entry
    cdef str current_cat, _id, val
    cdef list data, cats = [str(i) for i in range(1,7)], found_ids = []
    for _l in P:
        # prokka file is grouped into 6 categories, each requiring an addition of a column to the db table
        # Category found
        _line = <string>_l
        if str("".join([chr(_c) for _c in _line])).startswith("".join([chr(_c) for _c in delim])):
            # Get current category
            _dat = _line.substr(delim.size() + 1, 1)
            current_cat = "".join([chr(_c) for _c in _dat])
            # Skip over default category header line
            _l = next(P)
        else:
            _line = <string>_l
            line = _l.decode().split(",")
            # Store entry into dict
            entry = data_dict.get(line[0], None)
            if entry is None:
                data_dict[line[0]] = {current_cat: line[5]}
            else:
                data_dict[line[0]][current_cat] = line[5]
    if len(data_dict.keys()) > 0:
        W = open(outfile, "w")
        # Write condensed data to file
        W.write("Genome")
        for current_cat in cats:
            W.write("\t" + vir_cats[current_cat])
        W.write("\n")
        for _id in data_dict.keys():
            # Get sequence with corrected name based on virsorter-assigned fasta id
            W.write(
                "".join([chr(_c) for _c in
                         FastaParser.get_single(fasta_file, index=(int(_id.split("_")[-1])))[0]]) + os.path.splitext(fasta_file)[1]
            )
            for current_cat in cats:
                val = data_dict[_id].get(current_cat, None)
                if val and val != '':
                    W.write("\t" + val)
                else:
                    W.write("\t" + "0")
            W.write("\n")
        W.close()
