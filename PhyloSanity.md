# PhyloSanity

## About

**PhyloSanity** uses CheckM, GTDB-Tk, and FastANI to evaluate prokaryotic meta/genome completion, contamination,
phylogeny, and redundancy. This will generate a final **BioMetaDB** project containing the results of this pipeline.
An additional `.tsv` output file is generated.

- Required arguments
    - --directory (-d): directory of fasta files
    - --config_file (-c): config.ini file matching template in Examples/Config
- Optional flags
    - --biometadb_project (-b): Name to assign to **BioMetaDB** project, or name of existing project to use
    - --cancel_autocommit (-a): Cancel creation/update of **BioMetaDB** project
- Optional arguments
    - --output_directory (-o): Output prefix
    
## Example

- Example
    - `MetaSanity PhyloSanity -d fasta_folder/ -c metagenome_evaluation.ini -o eval 2>eval.err`
    - This command will use the fasta files in `fasta_folder/` in the evaluation pipeline. It will output to the folder
    `eval` and will use the config file entitled `metagenome_annotation.ini` to name the output database and table, and 
    to determine individual program arguments. Debugging and error messages will be saved to `eval.err`.
    - View a summary of the results of this pipeline using `dbdm SUMMARIZE -c Metagenomes/ -t evaluation`
<pre><code>SUMMARIZE:   View summary of all tables in database
 Project root directory:    Metagenomes
 Name of database:      Metagenomes.db

*******************************************************************************************
         Table Name:    evaluation  
    Number of Records:          10/10        

            Database    Average                 Std Dev     

          completion    92.882                  4.817       
       contamination    3.365                   2.574       
-------------------------------------------------------------------------------------------

            Database    Most Frequent           Number      Total Count 

              _class    Phycisphaerales         4           10          
              _order    SM1A02                  4           10          
              domain    Bacteria                10          10          
              family    Gimesia                 2           10          
               genus    Gimesia                 2           10          
         is_complete    True                    10          10          
     is_contaminated    False                   7           10          
    is_non_redundant    True                    10          10          
             kingdom    Planctomycetota         10          10          
              phylum    Phycisphaerae           4           10          
    redundant_copies    []                      10          10          
             species    maris                   1           10          
-------------------------------------------------------------------------------------------</code></pre>
    
## PhyloSanity config file

The **PhyloSanity** default config file allows program-level flags to be passed. Note that individual flags (e.g. those that are passed without arguments) are set using `FLAGS`.

### Configuring a pipeline

`CUTOFFS` defines the inclusive ANI value used to determine redundancy between two genomes, based on `FastANI`. 
`IS_COMPLETE` defines the inclusive minimum value to determine if a genome is complete, based on `CheckM`.
`IS_CONTAMINATED` defines the inclusive maximum value to determine if a genome is contaminated, based on `CheckM`. 

Deleting the `checkm_results` folder, the `fastani_results` folder, or the `gtdbtk_results` folder will cause its portion
of the pipeline to be rerun. By default, **PhyloSanity** parses results contained in these folders to determine completion 
and contamination, redundancy, and, optionally, phylogeny, respectively.

- Location: `Examples/Config/PhyloSanity.ini`
<pre><code># Docker/PhyloSanity.ini
# Default config file for running the FuncSanity pipeline
# DO NOT edit any PATH, DATA, or DATA_DICT variables
# Users are recommended to edit copies of this file only

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# The following pipes **MUST** be set

[CHECKM]
PATH = /usr/local/bin/checkm
# Do not remove this next flag
--tmpdir = /home/appuser/tmp_dir
--aai_strain = 0.95
-t = 1
--pplacer_threads = 1
FLAGS = --reduced_tree

[FASTANI]
PATH = /usr/bin/fastANI
--fragLen = 1500

[BIOMETADB]
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
    - CheckM and GTDBtk are both high memory-usage programs, often exceeding 100 GB. Use caution when multithreading. CheckM is required to run this pipeline.
    
### A note on flags

In general, program flags/arguments that filter or reduce output are supported, and thus can be provided in the user-passed
config file. **However, flags that change the output of individual programs (e.g. reordering, changing delimiter, etc.) may cause unsuspected issues, and thus are not
recommended.**
    
