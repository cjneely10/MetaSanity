#!/usr/bin/env python3
import sys
from BioMetaDB import get_table, UpdateData

USAGE = "Usage: python3 bowers_et_al_2017.py <biometadb-project>"

if "-h" in sys.argv:
    print(USAGE)
    exit()
assert len(sys.argv) == 2, USAGE

evaluation_data = get_table(sys.argv[1], "evaluation")
evaluation_data.query()

dt = UpdateData()
for genome in evaluation_data.keys():
    genome_id = genome.rstrip(".fna")
    genome_rl = get_table(sys.argv[1], table_name=genome_id)
    genome_rl.query("prokka LIKE 'tRNA%'")
    num_tRNAs = len(genome_rl)
    genome_rl.query("prokka == '23S ribosomal RNA'")
    has_23 = len(genome_rl) > 0
    genome_rl.query("prokka == '16S ribosomal RNA'")
    has_16 = len(genome_rl) > 0
    has_23_16_rRNA = has_23 and has_16
    completion = evaluation_data[genome].completion
    contamination = evaluation_data[genome].contamination
    # Bowers et al determinations for MAG/SAG assembly quality
    if num_tRNAs >= 18 and has_23_16_rRNA and completion > 90 and contamination < 5:
        dt[genome].setattr("quality", "high")
    elif completion >= 50 and contamination < 10:
        dt[genome].setattr("quality", "medium")
    elif completion < 50 and contamination < 10:
        dt[genome].setattr("quality", "low")
    else:
        dt[genome].setattr("quality", "incomplete")
        evaluation_data[genome].is_complete = False

evaluation_data.save()
evaluation_data.update(data=dt)
