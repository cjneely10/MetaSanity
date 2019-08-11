# cython: language_level=3
import os
from sys import stderr
import luigi
import subprocess
from collections import defaultdict
from MetaSanity.Accessories.ops import get_prefix
from MetaSanity.Parsers.tsv_parser import TSVParser
from MetaSanity.Parsers.fasta_parser import FastaParser
from MetaSanity.Accessories.range_ops import reduce_span
from MetaSanity.TaskClasses.luigi_task_class import LuigiTaskClass


class InterproscanConstants:
    INTERPROSCAN = "INTERPROSCAN"
    OUTPUT_DIRECTORY = "interproscan_results"
    AMENDED_RESULTS_SUFFIX = ".amended.tsv"
    STORAGE_STRING = "interproscan results"


class Interproscan(LuigiTaskClass):
    output_directory = luigi.Parameter()
    out_prefix = luigi.Parameter()
    fasta_file = luigi.Parameter()
    applications = luigi.ListParameter()

    def requires(self):
        return []

    def run(self):
        print("Running InterproScan..........")
        if not os.path.exists(str(self.output_directory)):
            os.makedirs(str(self.output_directory))
        cdef str outfile_name = os.path.join(str(self.output_directory), get_prefix(str(self.fasta_file)))
        cdef object outfile = open(outfile_name, "w")
        cdef str key
        if not os.path.isfile(os.path.join(str(self.output_directory), str(self.out_prefix) + ".tsv")):
            subprocess.run(
                [
                    "sed",
                    "s/\*//g",
                    str(self.fasta_file),
                ],
                check=True,
                stdout=outfile,
            )
            subprocess.run(
                [
                    str(self.calling_script_path),
                    "-i",
                    os.path.abspath(outfile_name),
                    "-o",
                    os.path.join(str(self.output_directory), str(self.out_prefix) + ".tsv"),
                    "-f",
                    "tsv",
                    *self.added_flags
                ],
                check=True,
                stdout=stderr,
            )
        write_interproscan_amended(
            os.path.join(str(self.output_directory), str(self.out_prefix) + ".tsv"),
            os.path.join(str(self.output_directory), str(self.out_prefix) + InterproscanConstants.AMENDED_RESULTS_SUFFIX),
            list(self.applications),
            set(FastaParser.index(str(self.fasta_file)))
        )
        os.remove(outfile_name)
        print("InterproScan complete!")

    def output(self):
        return luigi.LocalTarget(
            os.path.join(str(self.output_directory), str(self.out_prefix) + InterproscanConstants.AMENDED_RESULTS_SUFFIX)
        )


cdef void write_interproscan_amended(str interproscan_results, str outfile, list applications, set all_proteins):
    """ Function will write a shortened tsv version of the interproscan results in which
    columns are the applications that were run by the user
    
    :param interproscan_results:
    :param outfile: 
    :param applications:
    :param all_proteins: 
    :return: 
    """
    # interproscan indices are 0:id; 3:application; 4:sign_accession; 6:start_loc; 7:stop_loc; 11:iprlookup(opt);
    #                           13:goterms(opt); 14:pathways(opt)
    cdef tuple col_list = (0, 3, 4, 6, 7, 11, 13, 14)
    cdef str prot, sign_acn
    cdef str app, outstring = ""
    cdef list _l, interpro_results_list = TSVParser.parse_list(interproscan_results, col_list=col_list)
    cdef set interpro_ids = set([_l[0] for _l in interpro_results_list])
    cdef object W
    cdef list interpro_inner_list
    cdef dict stored_data
    cdef object inner_data
    cdef tuple coords, coord
    cdef dict condensed_results
    if interpro_ids:
        W = open(outfile, "w")
        W.write("ID")
        for app in applications:
            W.write("\t" + app)
        W.write("\n")
        condensed_results = {prot:{app: defaultdict(list) for app in applications} for prot in interpro_ids}
        # Build dict of data by sign_accession.
        for interpro_inner_list in interpro_results_list:
            # Check if data for sign_accession is initialized and set
            if len(interpro_inner_list) == 5:
                condensed_results[interpro_inner_list[0]][interpro_inner_list[1]][interpro_inner_list[2]].append(
                    (interpro_inner_list[3], interpro_inner_list[4]))
            else:
                condensed_results[interpro_inner_list[0]][interpro_inner_list[1]][interpro_inner_list[2]].append(
                    (interpro_inner_list[3], interpro_inner_list[4], *interpro_inner_list[5:]))
        # Sort results
        for prot, stored_data in condensed_results.items():
            for app, inner_data in stored_data.items():
                # Reduce to nonoverlapping ranges
                condensed_results[prot][app] = {sign_acn: reduce_span(inner_data[sign_acn]) for sign_acn in inner_data.keys()}
        # Write summarized results by protein
        for prot in condensed_results.keys():
            outstring = prot + ".faa" + "\t"
            for app in applications:
                if condensed_results[prot][app] != {}:
                    for sign_acn, coords in condensed_results[prot][app].items():
                        # Write as amended outstring to output file
                        outstring += "".join(
                            ["%s-%s:::%s;;;" % (coord[0], coord[1], sign_acn + (" " + " ".join(
                                coord[2:])[:-1] if len(coord) > 2 else "")[:-1]) for coord in coords])
                else:
                    outstring += "None"
                outstring += "\t"
            W.write(outstring[:-1] + "\n")
        W.close()
