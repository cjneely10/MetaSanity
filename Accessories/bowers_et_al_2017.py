#!/usr/bin/env python3
import sys
from BioMetaDB import get_table


assert len(sys.argv) == 2, "usage: python3 bowers_et_al_2017.py <biometadb-project>"

output_filename = "bowers-quality.tsv"
output_file = open(output_filename, "w")

evaluation_data = get_table(sys.argv[1], "evaluation")
evaluation_data.query()

output_file.write("ID\tquality\n")
for genome in evaluation_data.keys():
    genome_id = genome.rstrip(".fna")
    genome_rl = get_table(sys.argv[1], table_name=genome_id)
    genome_rl.query("prokka LIKE '%tRNA%'")
    num_tRNAs = len(genome_rl)
    genome_rl.query("prokka LIKE '%23S%'")
    has_23 = len(genome_rl) > 0
    genome_rl.query("prokka LIKE '%16S%'")
    has_16 = len(genome_rl) > 0
    has_23_16_rRNA = has_23 and has_16
    completion = evaluation_data[genome].completion
    contamination = evaluation_data[genome].contamination
    # Bowers et al determinations for MAG/SAG assembly quality
    if num_tRNAs >= 18 and has_23_16_rRNA and completion > 90 and contamination < 5:
        output_file.write(genome + "\thigh\n")
    elif completion >= 50 and contamination < 10:
        output_file.write(genome + "\tmedium\n")
    elif completion < 50 and contamination < 10:
        output_file.write(genome + "\tlow\n")
    else:
        output_file.write(genome + "\tincomplete\n")
        evaluation_data[genome].is_complete = False
evaluation_data.save()

output_file.close()

evaluation_data.update(data_file=output_filename)
