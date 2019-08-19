# PhyloSanity

## About

**PhyloSanity** uses `CheckM`, `GTDBtk`, and `FastANI` to evaluate prokaryotic meta/genome completion, contamination,
phylogeny, and redundancy. This will generate a final `BioMetaDB` project containing the results of this pipeline.
An additional `.tsv` output file is generated.

- Required arguments
    - --directory (-d): /path/to/directory of fasta files
    - --config_file (-c): /path/to/config.ini file matching template in Examples/Config
- Optional flags
    - --biometadb_project (-b): Name to assign to `BioMetaDB` project, or name of existing project to use
    - --cancel_autocommit (-a): Cancel creation/update of `BioMetaDB` project
- Optional arguments
    - --output_directory (-o): Output prefix
    
## Example

- Example
    - `MetaSanity PhyloSanity -d fasta_folder/ -c metagenome_evaluation.ini -o eval 2>eval.err`
    - This command will use the fasta files in `fasta_folder/` in the evaluation pipeline. It will output to the folder
    `eval` and will use the config file entitled `metagenome_annotation.ini` to name the output database and table, and 
    to determine individual program arguments. Debugging and error messages will be saved to `eval.err`.
    - View a summary of the results of this pipeline using `dbdm SUMMARIZE -c Metagenomes/ -t evaluation`
<pre><code>SUMMARIZE:	View summary of all tables in database
 Project root directory:	Metagenomes
 Name of database:		Metagenomes.db

*******************************************************************************************
             Table Name:        evaluation
        Number of Records:      201

             Column Name        Average                 Std Dev

              completion        83.504                  85.167
           contamination        2.231                   3.246
-------------------------------------------------------------------------------------------

             Column Name        Most Frequent           Num             Count Non-Null

             is_complete        True                    196             201
         is_contaminated        False                   176             201
        is_non_redundant        True                    139             201
               phylogeny        k__Bacteria             201             201
        redundant_copies        []                      99              201
-------------------------------------------------------------------------------------------</code></pre>
    
## PhyloSanity config file

The **PhyloSanity** pipeline involves the use of `CheckM`, `GTDBtk`, and `FastANI`. Its default config file allows for
paths to these calling programs to be set, as well as for program-level flags to be passed. Note that individual flags
(e.g. those that are passed without arguments) are set using `FLAGS`. Ensure that all paths are valid (the bash command
`which <COMMAND>` is useful for locating program paths).

### Configuring a pipeline

`CUTOFFS` defines the inclusive ANI value used to determine redundancy between two genomes, based on `FastANI`. 
`IS_COMPLETE` defines the inclusive minimum value to determine if a genome is complete, based on `CheckM`.
`IS_CONTAMINATED` defines the inclusive maximum value to determine if a genome is contaminated, based on `CheckM`. 

Deleting the `checkm_results` folder, the `fastani_results` folder, or the `gtdbtk_results` folder will cause its portion
of the pipeline to be rerun. By default, **PhyloSanity** parses results contained in these folders to determine completion 
and contamination, redundancy, and, optionally, phylogeny, respectively.

- Location: `Examples/Config/PhyloSanity.ini`
<pre><code># PhyloSanity.ini
# Default config file for running the PhyloSanity pipeline
# Users are recommended to edit copies of this file only

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# The following pipes **MUST** be set

[CHECKM]
PATH = /usr/local/bin/checkm
DATA = /path/to/checkm-db
--aai_strain = 0.95
-t = 1
--pplacer_threads = 1
FLAGS = --reduced_tree
--tmpdir = /path/to/tmpdir

[FASTANI]
PATH = /usr/local/bin/fastANI
--fragLen = 1500

[BIOMETADB]
PATH = /path/to/BioMetaDB/dbdm.py
--db_name = Metagenomes
--table_name = evaluation
--alias = eval
FLAGS = -s

[CUTOFFS]
ANI = 98.5
IS_COMPLETE = 50
IS_CONTAMINATED = 5


# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# The following pipe sections may optionally be set
# Ensure that the entire pipe section is valid,
# or deleted/commented out, prior to running pipeline


# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Phylogeny prediction

[GTDBTK]
PATH = /usr/local/bin/gtdbtk
--cpus = 1</code></pre>

- General Notes
    - `CheckM` and `GTDBtk` are both high memory-usage programs, often exceeding 100 GB. Use caution when multithreading.
    - `CheckM` writes to a temporary directory which may have separate user-rights, depending on the system on which it
    is installed. Users are advised to explicitly set the `--tmpdir` flag in `CHECKM` to a user-owned path.
    
### A note on flags

In general, program flags/arguments that filter or reduce output are supported, and thus can be provided in the user-passed
config file. However, flags that change the output of individual programs may cause unsuspected issues, and thus are not
recommended.
    
