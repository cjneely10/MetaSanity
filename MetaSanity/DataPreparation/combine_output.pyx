# cython: language_level=3
import os
import luigi
import pandas as pd
from MetaSanity.TaskClasses.luigi_task_class import LuigiTaskClass


class CombineOutputConstants:
    OUTPUT_DIRECTORY = "combined_results"
    HMM_OUTPUT_FILE = "combined.hmm"
    PROT_OUTPUT_FILE = "combined.protein"
    KO_OUTPUT_FILE = "combined.ko"
    CAZY_OUTPUT_FILE = "combined.cazy"
    MEROPS_OUTPUT_FILE = "combined.merops"
    MEROPS_PFAM_OUTPUT_FILE = "combined.merops.pfam"


class CombineOutput(LuigiTaskClass):
    output_directory = luigi.Parameter()
    directories = luigi.ListParameter()
    header_once = luigi.BoolParameter(default=False)
    join_header = luigi.BoolParameter(default=False)
    delimiter = luigi.Parameter(default="\t")
    na_rep = luigi.Parameter(default="0")

    def requires(self):
        return []

    def run(self):
        if not os.path.exists(str(self.output_directory)):
            os.makedirs(str(self.output_directory))
        cdef str directory
        cdef tuple suffixes
        cdef tuple prefixes
        cdef str output_file
        cdef str _f
        cdef object R
        cdef object _file
        cdef bint is_first = True
        cdef list files, output_results = []
        for directory, prefixes, suffixes, output_file, in self.directories:
            # Assumes that header lines are identical for all files
            if not self.join_header:
                _file = open(os.path.join(str(self.output_directory), output_file), "wb")
                for _f in filter_complete_list_with_prefixes(build_complete_file_list(directory, suffixes), prefixes):
                    # Write entire contents (for first file written or default)
                    if (self.header_once and is_first) or not self.header_once:
                        _file.write(open(_f, "rb").read())
                        is_first = False
                    # Write contents after first line
                    elif self.header_once and not is_first:
                        R = open(_f, "rb")
                        next(R)
                        _file.write(R.read())
                _file.close()
            # Gathers headers by first lines, minus first value, to write final output.
            else:
                # _df = False
                tsv = None
                for _f in filter_complete_list_with_prefixes(build_complete_file_list(directory, suffixes), prefixes):
                    if tsv is None:
                        tsv = TSVJoiner(_f)
                    else:
                        tsv.read_tsv(_f)
                if tsv is not None:
                    tsv.write_tsv(os.path.join(str(self.output_directory), output_file))
                    # # Gather tsv info
                    # if not _df:
                    #     df = pd.read_csv(_f, delimiter=str(self.delimiter), header=0, index_col="ID")
                    #     _df = True
                    # else:
                    #     df = df.combine_first(pd.read_csv(_f, delimiter=str(self.delimiter), header=0, index_col="ID"))
                # if _df and "is_extracellular" in df.columns:
                #
                #     df['is_extracellular'] = df['is_extracellular'].fillna(False).astype(bool)
                # if _df:
                #     df.to_csv(
                #         os.path.join(str(self.output_directory), output_file),
                #         sep="\t",
                #         na_rep=str(self.na_rep),
                #         index=True,
                #         index_label="ID",
                #     )


class CombineFunctionOutput(luigi.Task):
    output_directory = luigi.Parameter()
    data_files = luigi.ListParameter()
    delimiter = luigi.Parameter(default="\t")
    output_file = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        if not os.path.exists(str(self.output_directory)):
            os.makedirs(str(self.output_directory))
        tsv = None
        cdef str _file
        for _f in self.data_files:
            if tsv is None:
                tsv = TSVJoiner(_f)
            else:
                tsv.read_tsv(_f)

        tsv.write_tsv(os.path.join(str(self.output_directory), str(self.output_file)))


class TSVJoiner:
    def __init__(self, str tsv_file_path):
        self.header = set()
        self.data = {}
        self.is_empty = True
        if os.path.exists(tsv_file_path):
            self.read_tsv(tsv_file_path)

    def _join_header(self, list header):
        cdef str _h
        for _h in header:
            self.header.add(_h)

    def read_tsv(self, str tsv_file_path):
        self.is_empty = False
        cdef object R = open(tsv_file_path, "r")
        header = next(R).rstrip("\r\n").split("\t")
        cdef int header_len = len(header)
        data = None
        cdef str _line
        self._join_header(header[1:])
        for _line in R:
            line = _line.rstrip("\r\n").split("\t")
            data = self.data.get(line[0], None)
            if data is None:
                self.data[line[0]] = {}
            for i in range(1,header_len):
                self.data[line[0]][header[i]] = line[i]
        R.close()

    def write_tsv(self, str out_tsv_path):
        cdef str head
        cdef str _id
        if not self.is_empty:
            W = open(out_tsv_path, "w")
            header_list = list(self.header)
            _out = ""
            W.write("ID\t")
            for head in header_list:
                _out += head + "\t"
            W.write(_out[:-1] + "\n")
            for _id in self.data.keys():
                _out = _id + "\t"
                for head in header_list:
                    _out += self.data[_id].get(head, "None") + "\t"
                W.write(_out[:-1] + "\n")
            W.close()


def build_complete_file_list(str base_path, tuple suffixes):
    """ Moves over all directories in base_path and gathers paths of files with matching suffix in tuple of suffixes

    :param base_path:
    :param suffixes:
    :return:
    """
    cdef str root, filename, suffix
    cdef list dirnames, filenames
    cdef set out_paths = set()
    for root, dirnames, filenames in os.walk(base_path):
        for filename in filenames:
            for suffix in suffixes:
                if filename.endswith(suffix):
                    out_paths.add(os.path.join(root, filename))
    return list(out_paths)

def filter_complete_list_with_prefixes(list complete_file_list, tuple prefixes = ()):
    """ Filters list based on prefixes pased
    If none, returns list
    Otherwise, only retains files that match prefixes in file

    :param complete_file_list:
    :param prefixes:
    :return:
    """
    cdef str prefix, _file
    cdef list out_list = []
    if not prefixes:
        return complete_file_list
    for _file in complete_file_list:
        for prefix in prefixes:
            if os.path.basename(_file).split(".")[0] == prefix:
                out_list.append(_file)
    return out_list
