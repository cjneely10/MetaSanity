# distutils: language = c++
from libcpp.string cimport string
from libcpp.vector cimport vector


cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


cdef class CheckMParser:
    cdef vector[vector[string]] records

    def __init__(self, str file_name):
        self.read_file(file_name)

    def read_file(self, str file_name):
        cdef bytes _line
        cdef vector[string] line
        R = open(file_name, "rb")
        _line = next(R)
        while not _line.startswith(b"-"):
            _line = next(R)
        _line = next(R)
        _line = next(R)
        _line = next(R)
        while not _line.startswith(b"-"):
            l = _line.split()
            for _l in l:
                line.push_back(_l)
            self.records.push_back(line)
            line.clear()
            _line = next(R)
        R.close()

    def get_values(self):
        cdef vector[vector[string]] values_in_file = self.records
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
        cdef vector[vector[string]] values_in_file = self.records
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
        return checkM.get_values_as_dict()

    @staticmethod
    def parse_list(str file_name,):
        checkM = CheckMParser(file_name)
        return checkM.get_values()
