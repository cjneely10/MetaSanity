#!/usr/bin/env python3
import sys
from BioMetaDB import get_table, genomes


assert len(sys.argv) == 2, "usage: python3 bowers_et_al_2017.py <biometadb-project>"

genomes = genomes(sys.argv[1])

evaluation_data = get_table(sys.argv[1], "evaluation")
evaluation_data.query()

output_file = open("bowers-quality.tsv", "w")

output_file.write("ID\tquality\n")
for genome in genomes:
    genome_rl = get_table(sys.argv[1], table_name=genome)
    num_tRNAs = len(genome_rl.query("(prokka LIKE '%tRNA%) '"))
    has_23_16_rRNA = genome_rl.query("prokka LIKE '%23S%'") and genome_rl.query("prokka LIKE '%16S%'")
    completion = evaluation_data
