# MetaSanity

## Docker Installation
Download the install script from this repository.

<code><pre>wget https://github.com/cjneely10/MetaSanity/blob/master/install.py</pre></code>

This script requires `python3` and the `argparse` package. `wget`, `git`, `docker`, and `pip3` are also required.

<pre><code>usage: install.py [-h] -o OUTDIR [-v VERSION]

Download MetaSanity package

optional arguments:
  -h, --help            show this help message and exit
  -o OUTDIR, --outdir OUTDIR
                        Location to which to download MetaSanity package
  -v VERSION, --version VERSION
                        Default: docker</code></pre>

### Dependencies

See the [wiki page](https://github.com/cjneely10/MetaSanity/wiki/2-Installation) for installing all needed database files.
Python dependencies are best maintained within a separate Python virtual environment. `BioMetaDB` and `MetaSanity` must be contained and built within the same python environment. 

## About

**MetaSanity** is a wrapper-script for genome/metagenome evaluation tasks. This script will
run common evaluation and annotation programs and create a `BioMetaDB` project with the integrated results.

This wrapper script was built using the `luigi` Python package. 

## Usage Best Practices

#### Citations

Running a pipeline will output a bibtex citation file and sample in-text citations for use in academic writing and research.
Users are highly recommended to cite all items that are output in this file.

#### Config default files

Each genome pipeline has an associated configuration file that is needed to properly call the underlying programs.
Default files are available in the `Sample/Config` directory. To preserve these files for future use, users are recommended
to make edits only to copies of these default settings. Flags and arguments that are typically passed to individual programs
can be provided here.

#### Re-running steps in the pipeline

Although the data pipeline is made to run from start to finish, skipping completed steps as they are found, each major step 
("pipe") can be rerun if needed. Delete the pipe's output directory and call the given pipeline as listed in the `pipedm`
 section. If a **BioMetaDB** project is provided in the config file or passed as a command-line argument, its contents 
 will also be updated with the new results of this pipeline.

#### BioMetaDB

**MetaSanity** outputs a **BioMetaDB** project containing the completed results. By passing the `-a` flag, users can 
omit the creation or update of a given **BioMetaDB** project. Each pipeline outputs a final `.tsv` file of the results of
each individual pipe.

Multiple pipelines can be run using the same project - the results of each pipeline are stored as a new database table,
and re-running a pipeline will update the existing table within the **BioMetaDB** project.

#### Memory usage and time to completion estimates

Some programs in each pipeline can have very high memory requirements (>100GB) or long completion times (depending on 
the system used to run the pipeline). Users are advised to use a program such as `screen` or `nohup` to run this pipeline, 
as well as to redirect stderr to a separate file.

## MetaSanity

`MetaSanity.py` is the calling script for the docker installation. `pipedm.py` is the calling script for the standalone version of **MetaSanity**. 

<pre><code>usage: MetaSanity.py [-h] -d DIRECTORY -c CONFIG_FILE [-a] [-o OUTPUT_DIRECTORY]
                 [-b BIOMETADB_PROJECT] [-t TYPE_FILE]
                 program

MetaSanity: Run meta/genome evaluation and annotation pipelines

Available Programs:

FuncSanity: Runs gene callers and annotation programs on MAGs
                (Flags:  --directory --config_file --cancel_autocommit --output_directory --biometadb_project --type_file)
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
                        /path/to/type_file formatted as 'file_name.fna\t[Archaea/Bacteria]\t[gram+/gram-]\n'</code></pre>

The typical workflow involves creating a configuration file based on the templates in `Sample/Config`. This config
file is then used to call the given pipeline by passing to each program any flags specified by the user. This setup
allows users to customize the calling programs to better fit their needs, as well as provides a useful documentation
step for researchers.

### Usage differences - standalone script versus docker image

Both `MetaSanity.py` and `pipedm.py` use the same set of command-line arguments to function. 

- Docker installation
    - Users must edit the `MetaSanity.py` script to provide paths to downloaded data. See the [wiki page](https://github.com/cjneely10/MetaSanity/wiki/2-Installation) for instructions.
    - Users must use the config file templates found in `Sample/Config/Docker`.
- Source code installation
    - Users must edit the config file template found in `Sample/Config/SourceCode` to provide paths to working program installations.

## Available pipelines

- [PhyloSanity](PhyloSanity.md)
    - Evaluate MAGs for completion and contamination using `CheckM`, and evaluate set of passed genomes for redundancy
    using `FastANI`. Optionally predict phylogeny using `GTDBtk`.
    A final BioMetaDB project is generated, or updated, with a table that provides a summary of the results.
- [FuncSanity](FuncSanity.md)
    - Structurally and functionally annotate MAGs using several available annotation programs. Identify peptidase proteins,
    determine KEGG pathways, run PROKKA pipeline, predict viral sequences, and run interproscan.
    A final BioMetaDB project is generated, or updated, with a table that provides a summary of the results.
    
### Licensing notes

The use of `signalp` and `RNAmmer` requires accepting an additional academic license agreement upon download. Binaries for these
programs are thus not distributed with **MetaSanity**.
