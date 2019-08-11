from libcpp.string cimport string
from libcpp.vector cimport vector

cdef extern from "tsv_parser_cpp.cpp":
    pass

cdef extern from "tsv_parser_cpp.h" namespace "tsv":
    cdef cppclass TSVParser_cpp:
        TSVParser_cpp() except +
        TSVParser_cpp(string, string) except +
        int readFile(int, string, bint)
        string getHeader()
        vector[vector[string]] getValues()
