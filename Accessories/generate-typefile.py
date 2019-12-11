#!/usr/bin/env python3
import sys
from BioMetaDB import get_table, UpdateData

USAGE = "Usage: python3 generate-typefile.py <biometadb-project>"

if "-h" in sys.argv:
    print(USAGE)
    exit()
assert len(sys.argv) == 2, USAGE

evaluation_data = get_table(sys.argv[1], "evaluation")
evaluation_data.query()

# Gather Archaea/Bacteria type, gram+/- type
dt = UpdateData()
for genome in evaluation_data.keys():
    domain = evaluation_data[genome].domain.lower()
    if domain == "archaea":
        membrane_type = "gram+"
    else:
        membrane_type = "gram-"
    # Set biological domain and membrane type for each genome
    dt[genome].setattr("domain", domain)
    dt[genome].setattr("membrane_type", membrane_type)

# Store to tsv file
dt.to_file("typefile.list", skip_header=True, _order=["domain", "membrane_type"])
