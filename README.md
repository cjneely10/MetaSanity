# MetaSanity v1.2.0

## About

**MetaSanity v1.2.0** provides a unified workflow for genome assessment and functional annotation that combines
all outputs into a single queryable database – all within an easily distributed Docker image.

### [Installing MetaSanity](https://github.com/cjneely10/MetaSanity/wiki/2-Installation)
MetaSanity is available as a Docker installation and as a source code installation. Installation can be performed at the user level, limiting the need for contacting
University IT. See the [wiki page](https://github.com/cjneely10/MetaSanity/wiki/2-Installation) for complete installation instructions.

### [PhyloSanity](https://github.com/cjneely10/MetaSanity/wiki/3-PhyloSanity)
Evaluate MAGs for completion and contamination using CheckM, and evaluate redundancy using FastANI. Optionally predict phylogeny using GTDB-Tk.

### [FuncSanity](https://github.com/cjneely10/MetaSanity/wiki/4-FuncSanity)
Customize a functional annotation pipeline to include PROKKA, KEGG, InterProScan, the carbohydrate-active enzymes (CAZy) database, and the MEROPS database. Optionally, MEROPS matches can be filtered to target predicted outer membrane and extracellular proteins using PSORTb and SignalP4.1. KEGG results are processed through KEGG-Decoder to provide visual heatmaps of metabolic functions and pathways.

### [BioMetaDB](https://github.com/cjneely10/BioMetaDB)

BioMetaDB is a specialized relational database management system (RDBMS) project that integrates modularized storage and retrieval of FASTA records with the metadata describing them. This application uses tab-delimited data files to generate table relation schemas via Python3. Based on SQLAlchemy, BioMetaDB allows researchers to efficiently manage data from the command line by providing operations that include

- The ability to store information from any valid tab-delimited data file and to retrieve FASTA records or annotations related to these datasets by using SQL-optimized command-line queries.
- The ability to run all CRUD operations (create, read, update, delete) from the command line and from python scripts.

Output from both workflows is stored into a BioMetaDB project, providing users a simple interface to comprehensively examine their data. Users can query application results used across the entire genome set for specific information that is relevant to their research, allowing the potential to screen genomes based on returned taxonomy, quality, annotation, putative metabolic function, or any combination thereof.

### Examples 
Output a list, FASTA contigs, or FASTA proteins for:

- all genomes &gt;90% complete from the Family Pelagibacteraceae
- all genomes that contain extracellular MEROPS-detected peptidases
- all protein sequences of the nifH (K02588) in genomes &ge;70% complete with &lt;10% contamination

**PhyloSanity** and **FuncSanity** have large download requirements, making high-powered personal computers and academic servers the best option for running its analyses.
Once complete, the results can be analyzed using **BioMetaDB** on any computer that supports Python3.
    
### Licensing notes

The use of SignalP4.1 and RNAmmer1.2 requires accepting an additional academic license agreement upon download. Binaries for these programs are thus not distributed with **MetaSanity**.
