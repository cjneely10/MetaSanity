from libcpp.string cimport string

cdef extern from "<iostream>" namespace "std":
    cdef cppclass ostream:
        ostream& write(const char*, int) except +

# obviously std::ios_base isn't a namespace, but this lets
# Cython generate the correct C++ code
cdef extern from "<iostream>" namespace "std::ios_base":
    cdef cppclass open_mode:
        pass
    cdef open_mode binary
    # you can define other constants as needed

cdef extern from "<fstream>" namespace "std":
    cdef cppclass ofstream(ostream):
        # constructors
        ofstream(const char*) except +
        ofstream(const char*, open_mode) except+

    cdef cppclass ifstream(ostream):
        # constructors
        ifstream() except+
        ifstream(const char*) except +
        ifstream(const char*, open_mode) except+
        void open(const char*, open_mode) except+
        void close() except+

cdef extern from "reader_cpp.cpp":
    pass

cdef extern from "reader_cpp.h" namespace "reader":
    cdef cppclass KoFamScanReader_cpp:
        KoFamScanReader_cpp() except +
        void writeSimplified(string, string, string, string)
