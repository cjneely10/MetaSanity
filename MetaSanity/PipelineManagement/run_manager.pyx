# cython: language_level=3

class RunManager:
    def __init__(self, str list_file_path):
        """ Parses file for loading info into pipeline

        Format:

        prefix\tdata_file_1,data_file_2...\n

        :param list_file_path: (str)    /path/to/formatted_list_file.list
        """
        self._line_num = 0
        self._file_pointer = open(list_file_path, "rb")

    def get(self):
        """ Returns next line in file, split into assigned prefix and data files
        Increments line number for non-comment lines
        Automatically skips past commented lines

        :return Tuple[str, List[str]]:
        """
        self._line_num += 1
        cdef str prefix
        cdef list data_files = []
        cdef str data_file_line
        cdef str unedited_line
        cdef str data_file
        try:
            unedited_line = next(self._file_pointer).decode()
            while unedited_line.startswith("#"):
                unedited_line = next(self._file_pointer)
            prefix, data_file_line = unedited_line.rstrip("\r\n").split("\t")
            for data_file in data_file_line.split(","):
                data_files.append(data_file)
            return prefix, data_files
        except StopIteration:
            pass
        except ValueError as e:
            print("Line not formatted correctly:    prefix\\tfile.fq.gz,file2.fq.gz\\n", e)

    @property
    def line_num(self):
        """ Returns line number, not including comments (#)

        :return int:
        """
        return self._line_num
