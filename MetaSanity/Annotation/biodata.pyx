# cython: language_level=3
import luigi
import os
import subprocess
import pandas as pd
from MetaSanity.TaskClasses.luigi_task_class import LuigiTaskClass


class BioDataConstants:
    BIODATA = "BIODATA"
    OUTPUT_DIRECTORY = "biodata_results"
    HMM_PATH = "HMM_Models/expander_dbv0.6.hmm"
    OUTPUT_SUFFIX = ".final.tsv"
    OUTPUT_FILE = "KEGG"
    COMBINED_KEGG_FILE = "biodata.ko"
    COMBINED_HMM_FILE = "biodata.hmm"
    COMBINED_PROT_FILE = "biodata.prot"
    HMM_HEATMAP_OUT = "hmm_heatmap.svg"
    FUNCTION_HEATMAP_OUT = "function_heatmap.svg"
    STORAGE_STRING = "BioData results"


class BioData(LuigiTaskClass):
    output_directory = luigi.Parameter()
    hmmsearch_file = luigi.Parameter()
    out_prefix = luigi.Parameter()
    ko_file = luigi.Parameter()
    is_docker = luigi.BoolParameter(default=False)


    def requires(self):
        return []

    def run(self):
        print("Running BioData..........")
        if not os.path.exists(str(self.output_directory)):
            os.makedirs(str(self.output_directory))
        cdef str decoder_outfile = os.path.join(str(self.output_directory), str(self.out_prefix) + ".decoder.tsv")
        cdef str expander_outfile = os.path.join(str(self.output_directory), str(self.out_prefix) + ".expander.tsv")
        cdef str final_outfile = os.path.join(str(self.output_directory), str(self.out_prefix) + BioDataConstants.OUTPUT_SUFFIX)
        cdef list out_path = []
        cdef list calling_head = []
        if self.is_docker:
            out_path = ["-p", os.path.join(str(self.output_directory), "function_heatmap.svg")]
            calling_head = ["python", os.path.join(str(self.calling_script_path), "KEGG_decoder.py")]
        else:
            calling_head = ["KEGG-decoder"]
        # Combine mrna results
        # Run KEGG-decoder
        try:
            subprocess.run(
                [
                    *calling_head,
                    "-i",
                    str(self.ko_file),
                    "-o",
                    decoder_outfile,
                    *out_path,
                    "--vizoption",
                    "static",
                ],
                check=True,
            )
        except:
            subprocess.run(
                [
                    "python",
                    os.path.join(str(self.calling_script_path), "KEGG_decoder.py"),
                    "-i",
                    str(self.ko_file),
                    "-o",
                    decoder_outfile,
                    *out_path,
                    "--vizoption",
                    "static",
                ],
                check=True,
            )
        if self.is_docker:
            out_path = ["-p", os.path.join(str(self.output_directory), "hmm_heatmap.svg")]
        # Run KEGG-expander
        subprocess.run(
            [
                "python",
                os.path.join(str(self.calling_script_path), "KEGG_expander.py"),
                *out_path,
                str(self.hmmsearch_file),
                expander_outfile
            ],
            check=True,
        )
        if self.is_docker:
            out_path = ["-p", os.path.join(str(self.output_directory), "decode-expand_heatmap.svg")]
        # Run Decode_and_Expand.py
        subprocess.run(
            [
                "python",
                os.path.join(str(self.calling_script_path), "Decode_and_Expand.py"),
                *out_path,
                decoder_outfile,
                expander_outfile
            ],
            check=True,
        )
        # Write final output tsv file
        write_final_output_file(decoder_outfile, expander_outfile, final_outfile)
        print("BioData complete!")

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.out_prefix) + BioDataConstants.OUTPUT_SUFFIX))


"""
(Mostly) copy-pasted from Decode_and_Expand.py

"""
def write_final_output_file(str koala_list, str hmm_list, str output_file):

    koala = pd.read_csv(open(koala_list, "r"), index_col=0, sep="\t")
    hmm = pd.read_csv(open(hmm_list, "r"), index_col=0,sep="\t")
    output_df = koala.merge(hmm, left_index=True, right_index=True)

    #Reorganize column orientation to put like pathways together
    cols = output_df.columns.tolist()
    retinal_index = cols.index('Retinal biosynthesis')
    cols.insert(retinal_index+1, cols.pop(int(cols.index('beta-carotene 15,15-monooxygenase'))))
    cols.insert(retinal_index+2, cols.pop(int(cols.index('rhodopsin'))))
    trans_urea = cols.index('transporter: urea')
    cols.insert(trans_urea+1, cols.pop(int(cols.index('transporter: ammonia'))))
    nifH_index = cols.index('nitrogen fixation')
    cols.insert(nifH_index+1, cols.pop(int(cols.index('Vanadium-only nitrogenase'))))
    cols.insert(nifH_index+2, cols.pop(int(cols.index('Iron-only nitrogenase'))))
    dmsplyase_index = cols.index('DMSP demethylation')
    cols.insert(dmsplyase_index, cols.pop(int(cols.index('DMSP lyase (dddLQPDKW)'))))
    cols.insert(dmsplyase_index+1, cols.pop(int(cols.index('DMSP synthase (dsyB)'))))
    sulfitereductase_index = cols.index('dissimilatory sulfite < > sulfide')
    cols.insert(sulfitereductase_index+1, cols.pop(int(cols.index('DsrD dissimilatory sulfite reductase'))))
    output_df = output_df[cols]
    output_df.index = [idx.replace(".protein", "") + ".fna" for idx in output_df.index]
    output_df.index.name = "ID"
    print(output_df)
    output_df.to_csv(output_file, sep="\t")
