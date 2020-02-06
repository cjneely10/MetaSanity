# cython: language_level=3
import os
import luigi
from MetaSanity.Parsers.tsv_parser import TSVParser
from MetaSanity.Parsers.checkm_parser import CheckMParser
from MetaSanity.TaskClasses.luigi_task_class import LuigiTaskClass

"""
Class will combine .tsv output from CheckM and FastANI
Will output dictionary as:
    
    {
    "id":   {
                "is_non_redundant":     bint,
                "redundant_copies":     list,
                "contamination":        float,
                "is_contaminated":      bint,
                "completion":           float,
                "is_complete":          bint,
                "phylogeny":     str,
            }
    }

"""

_column_names = ["is_non_redundant", "redundant_copies",
                                  "contamination", "is_contaminated",
                                  "completion", "is_complete",
                                  "phylogeny"]


cdef class RedundancyChecker:
    cdef void* checkm_file
    cdef void* fastani_file
    cdef void* gtdbtk_file
    cdef dict cutoffs
    cdef dict output_data
    cdef dict file_ext_dict

    def __init__(self, str checkm_filename, str fastani_filename, str gtdbtk_filename, dict cutoff_values, dict file_ext_dict):
        self.cutoffs = cutoff_values
        self.checkm_file = <void *>checkm_filename
        self.fastani_file = <void *>fastani_filename
        self.gtdbtk_file = <void *>gtdbtk_filename
        self.output_data = {}
        self.file_ext_dict = file_ext_dict
        self._parse_records_to_categories()

    def _parse_records_to_categories(self):
        cdef dict checkm_results = CheckMParser.parse_dict(<object>self.checkm_file)
        cdef list _fastANI_results = TSVParser.parse_list(<object>self.fastani_file)
        gtdbtk_results = {}
        if len(_fastANI_results[0]) < 2:
            _fastANI_results = TSVParser.parse_list(<object>self.fastani_file, delimiter=" ")
        # GTDB-Tk optional
        # bac120 results
        if os.path.isfile(<object>self.gtdbtk_file):
            gtdbtk_results.update(TSVParser.parse_dict(<object>self.gtdbtk_file))
        file_name = str(<object>self.gtdbtk_file)
        file_name = os.path.join(
            os.path.dirname(file_name),os.path.basename(file_name).split(".")[0] + ".ar122.summary.tsv")
        # ar122 results
        if os.path.isfile(file_name):
            gtdbtk_results.update(TSVParser.parse_dict(file_name))
        cdef str max_completion_id
        cdef float max_completion
        cdef int i
        cdef str redundant_copies_str = "redundant_copies"
        cdef str completion_str = "completion"
        cdef str is_complete_str = "is_complete"
        cdef str is_contaminated_str = "is_contaminated"
        cdef str contamination_str = "contamination"
        cdef str is_non_redundant_str = "is_non_redundant"
        cdef str phylogeny_str = "phylogeny"
        cdef str key_and_ext
        cdef bint redundant_found
        cdef set redundant_genomes = set()
        cdef fastANI_results = {}
        for i in range(len(_fastANI_results)):
            key_and_ext = os.path.basename(_fastANI_results[i][0])
            if key_and_ext not in fastANI_results.keys():
                fastANI_results[key_and_ext] = []
            _fastANI_results[i][1] = os.path.basename(_fastANI_results[i][1])
            if key_and_ext != _fastANI_results[i][1]:
                fastANI_results[key_and_ext].append(_fastANI_results[i][1:])
        cdef set fastani_keys = set(fastANI_results.keys())
        for key in checkm_results.keys():
            # Assign by CheckM output
            key_and_ext = key + self.file_ext_dict[key]
            self.output_data[key_and_ext] = {}
            # Set gtdbtk value
            if gtdbtk_results.get(key) is not None:
                self.output_data[key_and_ext][phylogeny_str] = gtdbtk_results.get(key)[0]
            else:
                self.output_data[key_and_ext][phylogeny_str] = checkm_results.get(key)[2]
            # Initialize empty redundancy list
            self.output_data[key_and_ext][redundant_copies_str] = []
            # Completion value
            self.output_data[key_and_ext][completion_str] = float(checkm_results[key][0])
            # Set boolean based on CUTOFF values
            if self.output_data[key_and_ext][completion_str] <= float(self.cutoffs["IS_COMPLETE"]):
                self.output_data[key_and_ext][is_complete_str] = False
            else:
                self.output_data[key_and_ext][is_complete_str] = True
            # Contamination value
            self.output_data[key_and_ext][contamination_str] = float(checkm_results[key][1])
            # Set boolean based on CUTOFF values
            if self.output_data[key_and_ext][contamination_str] <= float(self.cutoffs["IS_CONTAMINATED"]):
                self.output_data[key_and_ext][is_contaminated_str] = False
            else:
                self.output_data[key_and_ext][is_contaminated_str] = True
            # Assign redundancy by fastANI:
            # If not on fastANI report, mark as non_redundant
            # Rename key to include file ext
            if key_and_ext in fastani_keys:
                for i in range(len(fastANI_results[key_and_ext])):
                    if float(fastANI_results[key_and_ext][i][1]) >= float(self.cutoffs["ANI"]):
                        self.output_data[key_and_ext][redundant_copies_str].append(fastANI_results[key_and_ext][i][0])
        # Update each key with a redundancy list to set non_redundant values for most complete
        for key in self.output_data.keys():
            if len(self.output_data[key][redundant_copies_str]) > 0:
                # Set max completion as first value
                max_completion = self.output_data[key][completion_str]
                # Get id of max completion
                max_completion_id = key
                for i in range(len(self.output_data[key][redundant_copies_str])):
                    # Update max completion percent as needed
                    if self.output_data[self.output_data[key][redundant_copies_str][i]][completion_str] > max_completion:
                        max_completion = self.output_data[self.output_data[key][redundant_copies_str][i]][completion_str]
                        max_completion_id = self.output_data[key][redundant_copies_str][i]
                # Move through list of redundant copies and set redundancy as needed
                for i in range(len(self.output_data[key][redundant_copies_str])):
                    if self.output_data[key][redundant_copies_str][i] != max_completion_id:
                        redundant_genomes.add(self.output_data[key][redundant_copies_str][i])

        for key in self.output_data.keys():
            if key not in redundant_genomes:
                self.output_data[key][is_non_redundant_str] = True
            else:
                self.output_data[key][is_non_redundant_str] = False


    def write_tsv(self, str file_name):
        """ Method will write all values in self.output_data to .tsv file

        :return:
        """
        cdef object W = open(file_name, "w")
        cdef str _id
        cdef str column_name
        # Write header
        W.write("ID")
        for column_name in _column_names:
            W.write("\t%s" % column_name)
        W.write("\n")
        # Write each line
        for _id in self.output_data.keys():
            W.write(_id)
            for column_name in _column_names:
                W.write("\t%s" % self.output_data[_id][column_name])
            W.write("\n")
        W.close()


class RedundancyParserTask(LuigiTaskClass):
    checkm_output_file = luigi.Parameter()
    fastANI_output_file = luigi.Parameter()
    gtdbtk_output_file = luigi.Parameter()
    cutoffs_dict = luigi.DictParameter()
    output_directory = luigi.Parameter(default="out")
    outfile = luigi.Parameter()
    file_ext_dict = luigi.DictParameter()

    def requires(self):
        return []

    def run(self):
        print("Beginning RedundancyParser..........")
        rc = RedundancyChecker(str(self.checkm_output_file),
                               str(self.fastANI_output_file),
                               str(self.gtdbtk_output_file),
                               dict(self.cutoffs_dict),
                               dict(self.file_ext_dict))
        rc.write_tsv(os.path.join(str(self.output_directory), str(self.outfile)))
        print("RedundancyParser complete!")

    def output(self):
        pass
