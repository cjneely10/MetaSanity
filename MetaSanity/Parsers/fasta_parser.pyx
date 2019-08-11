# distutils: language = c++
import os
from io import StringIO
from collections import deque
from libcpp.vector cimport vector
from fasta_parser cimport FastaParser_cpp


"""
FastaParser holds logic to call c++ optimized fasta parser

"""


cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


cdef class FastaParser:
    cdef FastaParser_cpp fasta_parser_cpp
    cdef ifstream* file_pointer
    cdef string file_prefix

    def __init__(self, str file_name, str delimiter=" ", str header=">"):
        if not os.path.isfile(file_name):
            raise FileNotFoundError(file_name)
        if not os.path.getsize(file_name) != 0:
            raise IOError(file_name)
        # Need as pointer in class object so the pointer is kept open over generator tasks
        self.file_pointer = new ifstream(<char *>PyUnicode_AsUTF8(file_name))
        self.fasta_parser_cpp = FastaParser_cpp(self.file_pointer[0],
                                                <string>PyUnicode_AsUTF8(delimiter),
                                                <string>PyUnicode_AsUTF8(header))

    def __del__(self):
        self.file_pointer.close()
        del self.file_pointer

    def create_tuple_generator(self, bint is_python = False):
        """ Generator function yields tuple of parsed fasta info

        :return:
        """
        cdef vector[string] record
        record.reserve(3);
        self.fasta_parser_cpp.grab(record)
        cdef int _c
        cdef str seq
        while record.size() == 3:
            # Yield tuple of str or string
            if is_python:
                yield (
                    "".join([chr(_c) for _c in record[0]]),
                    "".join([chr(_c) for _c in record[1]]),
                    "".join([chr(_c) for _c in record[2]]),
                )
            else:
                yield (
                    record[0],
                    record[1],
                    record[2],
                )
            self.fasta_parser_cpp.grab(record)
        return 1

    def create_string_generator(self, string simplify = "", int length = 80, bint include_descr = True):
        """ Generator function yields either python or c++ string

        :param length:
        :param simplify:
        :param include_descr:
        :return:
        """
        cdef vector[string] record
        record.reserve(3);
        cdef string record_name
        self.fasta_parser_cpp.grab(record)
        cdef int _c
        cdef int i = 0
        cdef str seq
        while record.size() == 3:
            if not include_descr:
                record = (record[0], <string>"", record[2])
            yield FastaParser.record_to_string(tuple(record), length=length, simplify=simplify, count=i)
            i += 1
            self.fasta_parser_cpp.grab(record)
        return None

    def get_values_as_dict(self, bint is_python = True):
        """ Get record, by record (as in iterate over file) and return as dict

        :return:
        """
        cdef object record_gen = self.create_tuple_generator(is_python)
        cdef tuple record
        cdef dict return_dict = {}
        try:
            while record_gen:
                record = next(record_gen)
                return_dict[record[0]] = (record[1], record[2])
        except StopIteration:
            return return_dict

    def get_index(self, bint is_python = True):
        """ Returns list of fasta ids in file

        :return:
        """
        cdef object record_gen = self.create_tuple_generator(is_python)
        cdef tuple record
        cdef list return_list = []
        try:
            while record_gen:
                return_list.append(next(record_gen)[0])
        except StopIteration:
            return return_list

    def get_values_as_list(self, bint is_python = True):
        """ Get record, by record (as in iterate over file) and return as list

        :return:
        """
        cdef object record_gen = self.create_tuple_generator(is_python)
        cdef list return_list = []
        try:
            while record_gen:
                return_list.append(next(record_gen))
        except StopIteration:
            return return_list

    @staticmethod
    def record_to_string(tuple record, int length = 80, int name_len = -1, string simplify = "", int count = 0):
        """ Method converts tuple c++ string record from (id, desc, seq) to standard fasta format

        :param record:
        :param length:
        :param name_len:
        :param simplify:
        :param count:
        :return:
        """
        cdef object tmp = record[0]
        cdef bint is_python
        if type(record[0]) == bytes:
            is_python = False
        else:
            is_python = True
        if name_len <= len(record[0]):
            tmp = (<string>tmp).substr(0, name_len)
        if simplify == "":
            record_name = tmp
        else:
            record_name = <string>"%s_%d" % (
                simplify,
                count
            )
        if is_python:
            return ">%s%s\n%s" % (
                "".join([chr(_c) for _c in record_name]),
                (" " + "".join([chr(_c) for _c in record[1]]) if record[1] else ""),
                FastaParser._reformat_py_sequence_to_length("".join([chr(_c) for _c in record[2]]), max_length=length),
            )
        else:
            return <string>">%s%s\n%s" % (
                record_name,
                (<string>" " + record[1] if record[1] else <string>""),
                FastaParser._reformat_string_sequence_to_length(record[2], max_length=length),
            )

    @staticmethod
    cdef str _reformat_py_sequence_to_length(str seq, int max_length = 80):
        """

        :param seq:
        :param max_length:
        :return:
        """
        cdef int seq_len = len(seq)
        cdef int seq_len_spit = int(len(seq) / max_length)
        cdef int i
        cdef object out_buffer = StringIO()
        for i in range(seq_len_spit - 1):
            out_buffer.write(seq[i * max_length: (i + 1) * max_length] + "\n")
        out_buffer.write(seq[seq_len_spit * max_length: seq_len])
        return out_buffer.getvalue()

    @staticmethod
    cdef string _reformat_string_sequence_to_length(bytes seq, int max_length = 80):
        """

        :param seq:
        :param max_length:
        :return:
        """
        cdef size_t seq_len = len(seq)
        cdef int seq_len_spit = int(len(seq) / max_length)
        cdef int i
        cdef string out_buffer
        for i in range(seq_len_spit + 1):
            out_buffer.append((<string>seq).substr(i * max_length, max_length) + <string>"\n")
        return out_buffer

    @staticmethod
    def write_records(str file_name, list fasta_record_ids, str outfile, object filter_func, str delimiter = " ",
                      str header = ">"):
        """ Static method will write a new file containing records found in file_name that match records in list.

        :param file_name:
        :param fasta_record_ids:
        :param outfile:
        :param filter_func:
        :param delimiter:
        :param header:
        :return:
        """
        cdef object W = open(outfile, "wb")
        cdef tuple record
        cdef object sorted_ids = deque(sorted(fasta_record_ids, key=filter_func))
        cdef object fp = FastaParser(file_name, delimiter, header)
        cdef object record_gen = fp.create_tuple_generator(False)
        try:
            while record_gen and len(sorted_ids) > 0:
                record = next(record_gen)
                if (<string>record[0]).compare(<string>PyUnicode_AsUTF8(sorted_ids[0])) == 0:
                    W.write(FastaParser.record_to_string(record))
                    sorted_ids.popleft()
        except StopIteration:
            W.close()

    @staticmethod
    def parse_list(str file_name, str delimiter = " ", str header = ">", bint is_python = True):
        """ Static method will return fasta file as list [(id, desc, seq),]

        :param is_python:
        :param file_name:
        :param delimiter:
        :param header:
        :return:
        """
        return FastaParser(file_name, delimiter, header).get_values_as_list(is_python)

    @staticmethod
    def parse_dict(str file_name, str delimiter = " ", str header = ">", bint is_python = True):
        """ Static method for creating dictionary from fasta file as id<str>: <tuple>(desc<str>(no id), seq<str>)

        :param is_python:
        :param file_name:
        :param delimiter:
        :param header:
        :return:
        """
        return FastaParser(file_name, delimiter, header).get_values_as_dict(is_python)

    @staticmethod
    def write_simple(str file_name, str out_file, str delimiter = " ", str header = ">", str simplify = "", int length = 80):
        """ Method will write a simplified version of a fasta file (e.g. only displays id and sequence)

        :param length:
        :param simplify:
        :param file_name:
        :param out_file:
        :param delimiter:
        :param header:
        :return:
        """
        cdef object fp = FastaParser(file_name, delimiter, header)
        cdef object W = open(out_file, "wb")
        cdef object record_gen = fp.create_string_generator(PyUnicode_AsUTF8(simplify), length, include_descr=False)
        try:
            while record_gen:
                W.write(next(record_gen))
        except StopIteration:
            W.close()

    @staticmethod
    def split(str file_name, str out_dir = "", str header = ">", str delimiter = " ", int name_len = -1):
        """ Method will split fasta file into individual files per fasta entry

        :param out_dir:
        :param file_name:
        :param header:
        :param delimiter:
        :param name_len:
        :return:
        """
        cdef object fp = FastaParser(file_name, delimiter, header)
        cdef object record_gen = fp.create_tuple_generator(False)
        cdef object W
        cdef list out_files = []
        cdef string out_file
        cdef tuple record
        try:
            while record_gen:
                record = next(record_gen)
                out_file = <string>PyUnicode_AsUTF8(
                    os.path.join(out_dir, "".join([chr(_c) for _c in record[0]]) + os.path.splitext(file_name)[1])
                )
                W = open("".join([chr(_c) for _c in out_file]), "wb")
                W.write(FastaParser.record_to_string(record, name_len=name_len))
                W.close()
                out_files.append(out_file)
        except StopIteration:
            return out_files

    @staticmethod
    def write_single(str file_name, str _id = "", int index = -1, str header = ">", str delimiter = " "):
        """ Method will search for a given fasta id or index and write to file (named by fasta header)

        :param file_name:
        :param _id:
        :param index:
        :param header:
        :param delimiter:
        :return:
        """
        assert not (_id == "" and index == -1), "Set _id or index only"
        cdef object W
        cdef tuple record = FastaParser.get_single(file_name, _id, index, header, delimiter)
        if record:
            W = open(record[0] + (<string>PyUnicode_AsUTF8(os.path.splitext(file_name)[1])), "wb")
            W.write(FastaParser.record_to_string(record))
            W.close()

    @staticmethod
    def get_single(str file_name, str _id = "", int index = -1, str header = ">", str delimiter = " "):
        """ Method will search for a given fasta id or index (named by fasta header) and returns record as tuple

        :param file_name:
        :param _id:
        :param index:
        :param header:
        :param delimiter:
        :return:
        """
        assert not (_id == "" and index == -1), "Set _id or index only"
        cdef object fp = FastaParser(file_name, delimiter, header)
        cdef object record_gen = fp.create_tuple_generator(False)
        cdef tuple record = (1,1,1)
        cdef int i = 0
        try:
            while record_gen:
                record = next(record_gen)
                if (_id != "" and (<string>record[0]).compare(<string>PyUnicode_AsUTF8(_id)) == 0) or \
                        (index != -1 and i == index):
                    return record
                i += 1
        except StopIteration:
            del fp
            return None

    @staticmethod
    def index(str file_name, str header = ">", str delimiter = " "):
        """ Gets fasta ids from file

        :param file_name:
        :param header:
        :param delimiter:
        :return:
        """
        return FastaParser(file_name, delimiter, header).get_index(True)
