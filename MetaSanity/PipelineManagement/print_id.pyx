# cython: language_level=3
import luigi


class PrintID(luigi.Task):
    out_prefix = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        print("Running annotation for %s.........." % str(self.out_prefix))
