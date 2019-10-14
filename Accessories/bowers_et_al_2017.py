#!/usr/bin/env python3
import sys
from BioMetaDB import get_table, genomes


assert len(sys.argv) == 2, "usage: python3 bowers_et_al_2017.py <biometadb-project>"

genomes = genomes(sys.argv[1])

evaluation_data = get_table(sys.argv[1], "evaluation")
evaluation_data.query()

output_filename = "bowers-quality.tsv"
output_file = open(output_filename, "w")

output_file.write("ID\tquality\n")
for genome in genomes:
    genome_rl = get_table(sys.argv[1], table_name=genome)
    num_tRNAs = len(genome_rl.query("(prokka LIKE '%tRNA%) '"))
    has_23_16_rRNA = genome_rl.query("prokka LIKE '%23S%'") and genome_rl.query("prokka LIKE '%16S%'")
    completion = evaluation_data[genome].completion
    contamination = evaluation_data[genome.contamination]
    # High quality
    if num_tRNAs >= 18 and has_23_16_rRNA and completion > 90 and contamination < 5:
        output_file.write(genome + "\thigh\n")
    elif completion >= 50 and contamination < 10:
        output_file.write(genome + "\tmedium\n")
    elif completion < 50 and contamination < 10:
        output_file.write(genome + "\tlow\n")
    else:
        output_file.write(genome + "\tincomplete\n")

output_file.close()

evaluation_data.update(data_file=output_filename)
