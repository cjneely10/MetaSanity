# distutils: language = c++
from MetaSanity.Parsers.fasta_parser import FastaParser
from libcpp.string cimport string
import os
from decimal import Decimal


cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


def blast_to_fasta(str fasta_file, str blast_file, str out_file, int get_column = 0, tuple coords_columns = (2,3),
                   double e_value = 1e-10, float pident = 98.5, tuple eval_pident_columns = (4,5), bint write_matches = True):
    """ Function will take the results of a blastx search and output corresponding
    fasta records from a file. Must provide the index of the column with id to get as int.
    Must also provide a tuple for the indices of the start/end coordinates, as well as for the indices of the evalue
    and pident columns. Option to write file that matches newly created id to the original fasta record id.

    :param fasta_file:
    :param blast_file:
    :param out_file:
    :param get_column:
    :param coords_columns:
    :param e_value:
    :param pident:
    :param eval_pident_columns:
    :param write_matches:
    :return:
    """
    cdef dict fasta_records = FastaParser.parse_dict(fasta_file, is_python=False)
    cdef object W = open(out_file, "wb")
    cdef object _blast_file = open(blast_file, "rb")
    cdef object WM = open(os.path.splitext(out_file)[0] + ".matches", "wb")
    cdef list line
    cdef bytes _line
    cdef tuple record
    cdef tuple coords
    cdef string record_id
    for _line in _blast_file:
        line = _line.decode().rstrip("\r\n").split("\t")
        coords = (int(line[coords_columns[0]]), int(line[coords_columns[1]]))
        coords = tuple(sorted(coords))
        # Locate record based on column index and coords tuple passed
        if e_value <= Decimal(line[eval_pident_columns[0]]) and pident >= float(line[eval_pident_columns[1]]):
            record_id = <string>PyUnicode_AsUTF8(line[get_column])
            record = fasta_records.get(record_id, None)
            if record:
                record = (
                    record_id + <string>"-%i_%i" % coords,
                    <string>" %s" % record[0],
                    (<string>record[1]).substr(coords[0] - 1, coords[1] - coords[0] + 1)
                )
                W.write(FastaParser.record_to_string(record))
                if write_matches:
                    WM.write(<string>"%s\t%s\n" % (
                        record_id + <string>"-%i_%i" % coords,
                        <string>PyUnicode_AsUTF8(line[get_column + 1])
                    ))
    W.close()
    WM.close()
    _blast_file.close()
