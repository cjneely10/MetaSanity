# cython: language_level=3

import luigi
import os
import shutil


class FileOperations(luigi.Task):
    data_files = luigi.ListParameter(default=[])
    data_folder = luigi.Parameter(default="")


class Remove(FileOperations):
    def requires(self):
        return []

    def output(self):
        return []

    def run(self):
        cdef str file_name
        for file_name in self.data_files:
            os.remove(file_name)
        if str(self.data_folder) != "" and os.path.exists(str(self.data_folder)):
            shutil.rmtree(str(self.data_folder))


class Move(FileOperations):
    move_directory = luigi.Parameter()
    prior_directory = luigi.Parameter(default="")

    def requires(self):
        return []

    def output(self):
        return []

    def run(self):
        cdef str file_name
        for file_name in self.data_files:
            shutil.move(os.path.join(self.prior_directory, file_name),
                        os.path.join(self.move_directory, file_name))
