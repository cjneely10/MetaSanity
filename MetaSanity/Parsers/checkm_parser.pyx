# distutils: language = c++
import os
from checkm_parser cimport CheckMParser_cpp
from libcpp.vector cimport vector


cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


cdef class CheckMParser:
    cdef CheckMParser_cpp checkm_parser_cpp

    def __init__(self, str file_name):
        if os.path.exists(file_name):
            self.checkm_parser_cpp = CheckMParser_cpp(<string>PyUnicode_AsUTF8(file_name))

    def read_file(self):
        self.checkm_parser_cpp.readFile()

    def get_values(self):
        cdef vector[vector[string]] values_in_file = self.checkm_parser_cpp.getValues()
        cdef size_t i
        # return return_list
        return [
            ["".join(chr(val) for val in values_in_file[i][0]),
                float(values_in_file[i][12]),
                float(values_in_file[i][13]),
                values_in_file[i][1],]
            for i in range(values_in_file.size()) if values_in_file[i].size() > 0
        ]

    def get_values_as_dict(self):
        cdef vector[vector[string]] values_in_file = self.checkm_parser_cpp.getValues()
        cdef size_t i
        cdef string val
        # return return_list
        return {"".join([chr(_c) for _c in values_in_file[i][0]]):
                [float(values_in_file[i][12]),
                float(values_in_file[i][13]),
                "".join([chr(_c) for _c in values_in_file[i][1]]),]
                for i in range(values_in_file.size())
                if values_in_file[i].size() > 0}

    @staticmethod
    def parse_dict(str file_name,):
        checkM = CheckMParser(file_name)
        checkM.read_file()
        return checkM.get_values_as_dict()

    @staticmethod
    def parse_list(str file_name,):
        checkM = CheckMParser(file_name)
        checkM.read_file()
        return checkM.get_values()
