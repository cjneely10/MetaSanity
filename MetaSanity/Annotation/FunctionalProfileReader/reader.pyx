# distutils: language = c++
import os
from libcpp.string cimport string


"""
Class reads kofamscan results file and functional profiles file
Determines if function is present in kofamscan results

"""

cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


cdef class KoFamScan:
    @staticmethod
    def write_highest_matches(str kofamscan_results, str outfile, str suffix = "", str header = ""):
        cdef KoFamScanReader_cpp reader
        reader = KoFamScanReader_cpp()
        reader.writeSimplified(
            <string>PyUnicode_AsUTF8(kofamscan_results),
            <string>PyUnicode_AsUTF8(outfile),
            <string>PyUnicode_AsUTF8(suffix),
            <string>PyUnicode_AsUTF8(header),
        )
