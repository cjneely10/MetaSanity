# MetaSanity

## Quick Install
See the [wiki page](https://github.com/cjneely10/MetaSanity/wiki/2-Installation) for a complete set of installation instructions.
Download the install script from this repository.

`wget https://raw.githubusercontent.com/cjneely10/MetaSanity/master/install.py && chmod +x install.py`

If desired, create and source a python virtual environment.
This script requires `python3` and the `argparse` package. `wget`, `git`, `docker`, and `pip` are also required.


<pre><code>usage: install.py [-h] [-o OUTDIR] [-v VERSION]

Download MetaSanity package

optional arguments:
  -h, --help            show this help message and exit
  -o OUTDIR, --outdir OUTDIR
                        Location to which to download MetaSanity package, default MetaSanity
  -v VERSION, --version VERSION
                        Default: docker</code></pre>

### Dependencies

Python dependencies are best maintained within a separate Python virtual environment. `BioMetaDB` and `MetaSanity` must be contained and built within the same python environment. 

## About

**MetaSanity** is a wrapper-script for genome/metagenome evaluation tasks. This script will
run common evaluation and annotation programs and create a `BioMetaDB` project with the integrated results.

This wrapper script was built using the `luigi` Python package. 

MetaSanity provides a unified workflow for genome assessment and functional annotation that combines
all outputs into a single queryable database – all within an easily distributed Docker image
The database is constructed through the two branches of the MetaSanity pipeline.

### [PhyloSanity](PhyloSanity.md)
Evaluate MAGs for completion and contamination using CheckM, and evaluate set of passed genomes for redundancy using FastANI. Optionally predict phylogeny using GTDB-Tk. A final BioMetaDB project is generated, or updated, with a table that provides a summary of the results.

### [FuncSanity](FuncSanity.md)
Provides functional annotation options through PROKKA, KEGG, InterProScan, the carbohydrate-active enzymes (CAZy) database, and the MEROPS database. Optionally, MEROPS matches can be filtered to target predicted outer membrane and extracellular proteins using PSORTb and SignalP. KEGG results are processed through KEGG-Decoder to provide visual heatmaps of metabolic functions and pathways BioMetaDB – the powerhouse behind MetaSanity, all outputs are queryable.

### BioMetaDB

**MetaSanity** outputs a **BioMetaDB** project containing the completed results. By passing the `-a` flag, users can 
omit the creation or update of a given **BioMetaDB** project. Each pipeline outputs a final `.tsv` file of the results of
each individual pipe.

Multiple pipelines can be run using the same project - the results of each pipeline are stored as a new database table,
and re-running a pipeline will update the existing table within the **BioMetaDB** project.

### Examples 
Output a list, FASTA contigs, or FASTA proteins for:

- all genomes &gt;90% complete from the Family Pelagibacteraceae
- all genomes that contain extracellular MEROPS-detected peptidases
- all protein sequences of the nifH (K02588) in genomes &gt;70% complete with &lt;10% contamination

Installation can be performed at the user level by the user, limiting the need for contacting
University IT and (except for the memory intensive programs like GTDB-Tk) can be run locally
on many laptops.

## Usage Best Practices

#### Citations

Running a pipeline will output a sample citation file for use in academic writing and research.
Users are highly recommended to cite all items that are output in this file.

#### Config default files

Each genome pipeline has an associated configuration file that is needed to properly call the underlying programs.
Default files are available in the `Sample/Config` directory. To preserve these files for future use, users are recommended
to make edits only to copies of these default settings. Flags and arguments that are typically passed to individual programs
can be provided here.

#### Re-running steps in the pipeline

Although the data pipeline is made to run from start to finish, skipping completed steps as they are found, each major step 
("pipe") can be rerun if needed. Delete the pipe's output directory and rerun the `MetaSanity.py` script. If a **BioMetaDB** project is provided in the config file or passed as a command-line argument, its contents 
 will also be updated with the new results of this pipeline.

#### Memory usage and time to completion estimates

Some programs in each pipeline can have very high memory requirements (>100GB) or long completion times (depending on 
the system used to run the pipeline). Users are advised to use a program such as `screen` or `nohup` to run this pipeline, 
as well as to redirect stderr to a separate file.

## MetaSanity

`MetaSanity.py` is the calling script for the docker installation. `pipedm.py` is the calling script for the standalone version of **MetaSanity**. 

<pre><code>usage: MetaSanity.py [-h] -d DIRECTORY -c CONFIG_FILE [-a]
                     [-o OUTPUT_DIRECTORY] [-b BIOMETADB_PROJECT]
                     [-t TYPE_FILE] [-p]
                     program

MetaSanity:	Run meta/genomes evaluation and annotation pipelines

Available Programs:

FuncSanity: Runs gene callers and annotation programs on MAGs
		(Flags:  --directory --config_file --cancel_autocommit --output_directory --biometadb_project --type_file --prokka)
PhyloSanity: Evaluates completion, contamination, and redundancy of MAGs
		(Flags:  --directory --config_file --cancel_autocommit --output_directory --biometadb_project)

positional arguments:
  program               Program to run

optional arguments:
  -h, --help            show this help message and exit
  -d DIRECTORY, --directory DIRECTORY
                        Directory containing genomes
  -c CONFIG_FILE, --config_file CONFIG_FILE
                        Config file
  -a, --cancel_autocommit
                        Cancel commit to database
  -o OUTPUT_DIRECTORY, --output_directory OUTPUT_DIRECTORY
                        Output directory prefix, default out
  -b BIOMETADB_PROJECT, --biometadb_project BIOMETADB_PROJECT
                        /path/to/BioMetaDB_project (updates values of existing database)
  -t TYPE_FILE, --type_file TYPE_FILE
                        /path/to/type_file formatted as 'file_name.fna\t[Archaea/Bacteria]\t[gram+/gram-]\n'
  -p, --prokka          Use PROKKA gene calls instead of prodigal search</code></pre>

The typical workflow involves creating a configuration file based on the templates in `Sample/Config`. This config
file is then used to call the given pipeline by passing to each program any flags specified by the user. This setup
allows users to customize the calling programs to better fit their needs, as well as provides a useful documentation
step for researchers.
    
### Licensing notes

The use of `signalp` and `RNAmmer` requires accepting an additional academic license agreement upon download. Binaries for these programs are thus not distributed with **MetaSanity**.
