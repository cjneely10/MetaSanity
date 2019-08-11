from libcpp.string cimport string
from libcpp.vector cimport vector

cdef extern from "checkm_parser_cpp.cpp":
    pass

cdef extern from "checkm_parser_cpp.h" namespace "checkm":
    cdef cppclass CheckMParser_cpp:
        CheckMParser_cpp() except +
        CheckMParser_cpp(string) except +
        void readFile()
        vector[vector[string]] getValues()
