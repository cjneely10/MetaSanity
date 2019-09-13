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
                # combined_results = pd.DataFrame(index="ID")
                # files = []
                _df = False
                for _f in filter_complete_list_with_prefixes(build_complete_file_list(directory, suffixes), prefixes):
                    # Gather tsv info
                    # files.append(os.path.basename(_f))
                    if not _df:
                        df = pd.read_csv(_f, delimiter=str(self.delimiter), header=0, index_col="ID",
                                         true_values=['True',], false_values=['False',])
                        _df = True
                    else:
                        df = df.combine_first(pd.read_csv(_f, delimiter=str(self.delimiter), header=0, index_col="ID",
                                                          true_values=['True',], false_values=['False',]))
                    # boolean_df = df.select_dtypes(bool)
                    # booleanDictionary = {True: 'True', False: 'False'}
                    # for column in boolean_df:
                    #     df[column] = df[column].map(booleanDictionary)
                if _df and "is_extracellular" in df.columns:
                    df['is_extracellular'] = df['is_extracellular'].astype('bool')
                    # output_results.append()
                # combined_results = combined_results.join(output_results)
                if _df:
                    # new_df = pd.concat(output_results, axis=1, sort=False)
                    df.to_csv(
                        os.path.join(str(self.output_directory), output_file),
                        sep="\t",
                        na_rep=str(self.na_rep),
                        index=True,
                        index_label="ID",
                    )

    # def output(self):
    #     return [
    #         luigi.LocalTarget(os.path.join(str(self.output_directory), directory, output_file))
    #         for directory, prefixes, suffixes, output_file
    #         in self.directories
    #     ]


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
            if os.path.basename(_file).startswith(prefix):
                out_list.append(_file)
    return out_list
