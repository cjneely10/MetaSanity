# cython: language_level=3

import os
import luigi
import shutil
import subprocess
from random import randint
from datetime import datetime
from MetaSanity.TaskClasses.luigi_task_class import LuigiTaskClass


class CheckMConstants:
    CHECKM = "CHECKM"
    OUTPUT_DIRECTORY = "checkm_results"
    OUTFILE = "checkm_lineageWF_results.qa.txt"


class CheckM(LuigiTaskClass):
    outfile = luigi.Parameter(default=CheckMConstants.OUTFILE)
    output_directory = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        """ checkm lineage_wf -x .fna --aai_strain 0.95 -t 10 --pplacer_threads 10 ./genome_folder
            output_directory > checkm_lineageWF_results.qa.txt

        Note that python2 is required to run checkm

        :return:
        """
        if not os.path.exists(str(self.output_directory)):
            os.makedirs(str(self.output_directory))
        cdef str tmp_dir = os.path.join(os.path.dirname(str(self.output_directory)),
                                        "%s_%s_outdir" % (datetime.today().strftime("%Y%m%d"), str(randint(1,1001))))
        if not os.path.exists(tmp_dir):
            os.makedirs(tmp_dir)
        cdef object tmp = open(os.path.join(tmp_dir, "tmp.txt"), "w")
        print("Running CheckM..........")
        # db_set = subprocess.Popen(
        #     [
        #         "echo",
        #         "/home/appuser/checkm\n/home/appuser/checkm",
        #     ],
        #     stdout=subprocess.PIPE,
        # )
        # subprocess.run(
        #     [
        #         "checkm",
        #         "data",
        #         "setRoot",
        #     ],
        #     stdin=db_set.stdout
        # )
        # Run evaluation
        subprocess.run(
            [
                str(self.calling_script_path),
                "lineage_wf",
                *self.added_flags,
                str(self.fasta_folder),
                str(self.output_directory)
            ],
            check=True,
            stdout=tmp,
        )
        shutil.move(os.path.join(tmp_dir, "tmp.txt"), os.path.join(str(self.output_directory), str(self.outfile)))
        shutil.rmtree(tmp_dir)
        print("CheckM complete!")

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.outfile)))
