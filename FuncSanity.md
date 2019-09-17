# FuncSanity

## About

**FuncSanity** uses `prodigal`, `kofamscan`, `interproscan`, `PROKKA`, `VirSorter`, `psortb`, `signalp`, and `KEGGDecoder`
to structurally and functionally annotate contig data. This will generate a final `BioMetaDB` project containing integrated 
results of this pipeline. An additional `.tsv` output file is generated summarizing each "pipe" in the pipeline's config file.
Users have the option of using prodigal gene calls or PROKKA-annotated gene calls in downstream analysis.
The peptidase pipe requires the latest `dbCAN` and `CAZy` HMM profiles, whose links are available on the main README.
The peptidase pipe also requires the file `merops-as-pfams.txt`, which is available in `Sample/Data`. 

- Required arguments
    - --directory (-d): directory of fasta files
    - --config_file (-c): config.ini file matching template in Sample/Config
- Optional flags
    - --prokka (-p): Use prokka gene calls in downstream analysis
    - --cancel_autocommit (-a): Cancel creation/update of `BioMetaDB` project
- Optional arguments
    - --output_directory (-o): Output prefix
    - --biometadb_project (-b): Name to assign to `BioMetaDB` project, or name of existing project to use
    - --type_file (-t): /path/to/type_file, formatted as `'file_name.fna\t[Archaea/Bacteria]\t[gram+/gram-]\n'`
        - This argument is only required if running the **peptidase** portion of the pipeline on non gram- bacteria.

## Example

- `MetaSanity FuncSanity -d fasta_folder/ -c metagenome_annotation.ini -o annot 2>annot.err`
- This command will use the fasta files in `fasta_folder/` in the annotation pipeline. It will output to the folder
`annot` and will use the config file entitled `metagenome_annotation.ini` to name the output database and to determine 
individual program arguments. Debugging and error messages will be saved to `annot.err`.
- This pipeline will generate a series of tables - a summary table, whose name is user-provided in the config file, as 
well as an individual table for each genome provided that describes annotations for each protein sequence identified
from the starting contigs.
<pre><code>SUMMARIZE:	View summary of all tables in database
 Project root directory:	Planctomycetes
 Name of database:		Planctomycetes.db

**********************************************************************************************
                Table Name:     tara-psw-mag-00018
         Number of Records:     3791

                Column Name     Average                 Std Dev

        num_phage_contigs_1     0.000                   0.000
        num_phage_contigs_2     0.000                   0.000
        num_phage_contigs_3     0.000                   0.000
            num_prophages_1     0.000                   0.000
            num_prophages_2     0.001                   0.051
            num_prophages_3     0.000                   0.000
----------------------------------------------------------------------------------------------

        Column Name     Most Frequent           Frequency       Total Count

               cazy     GT41                    40              720
                cdd     cd06267                 161             1447
              hamap     MF_01217 IPR00323...    4               410
                 ko     K03406                  18              1497
        merops_pfam     PF00326                 10              35
            panther     PTHR30093               232             2994
               pfam     PF07963 IPR012902...    237             3469
             prodom     PD004647                9               57
               sfld     SFLDS00029 IPR007...    13              42
              smart     SM00710 IPR006626...    190             952
        superfamily     SSF54523                246             3226
            tigrfam     TIGR02532 IPR0129...    243             1041
--------------------------------------------------------------------------------------</code></pre>
- View the summary table using `dbdm SUMMARIZE -c Metagenomes/ -t annotation`
<pre><code>SUMMARIZE:	View summary of all tables in database
 Project root directory:	Metagenomes
 Name of database:		Metagenomes.db
 
******************************************************************************************************************
                                                 Table Name:	annotation  
                                          Number of Records:	##         

                                                 Column Name	Average     	Std Dev   

                                  3hydroxypropionate_bicycle	#.###       	#.###       
                          4hydroxybutyrate3hydroxypropionate	#.###       	#.###       
                                                    adhesion	#.###       	#.###       
                                             alcohol_oxidase	#.###       	#.###       
                                                alphaamylase	#.###       	#.###       
                             alt_thiosulfate_oxidation_doxad	#.###       	#.###       
                              alt_thiosulfate_oxidation_tsda	#.###       	#.###       
                                            aminopeptidase_n	#.###       	#.###       
                                   ammonia_oxidation_amopmmo	#.###       	#.###              
                (...)            
                                          competence_factors	#.###       	#.###       
                           competencerelated_core_components	#.###       	#.###       
                        competencerelated_related_components	#.###       	#.###       
                                      cp_lyase_cleavage_phnj	#.###       	#.###       
                                             cplyase_complex	#.###       	#.###       
                                              cplyase_operon	#.###       	#.###       
                                 curli_fimbriae_biosynthesis	#.###       	#.###             
                (...)           
                                                     rubisco	#.###       	#.###       
                                                      secsrp	#.###       	#.###       
                     serine_pathwayformaldehyde_assimilation	#.###       	#.###       
                               soluble_methane_monooxygenase	#.###       	#.###       
                                             sulfhydrogenase	#.###       	#.###       
                                           sulfide_oxidation	#.###       	#.###       
                                       sulfite_dehydrogenase	#.###       	#.###       
                               sulfite_dehydrogenase_quinone	#.###       	#.###       
                                     sulfolipid_biosynthesis	#.###       	#.###       
                (...)          
                                          type_iii_secretion	#.###       	#.###       
                                           type_iv_secretion	#.###       	#.###       
                                         type_vabc_secretion	#.###       	#.###       
                                           type_vi_secretion	#.###       	#.###       
                             ubiquinolcytochrome_c_reductase	#.###       	#.###       
                                    vanadiumonly_nitrogenase	#.###       	#.###       
                                                vtype_atpase	#.###       	#.###       
                                               woodljungdahl	#.###       	#.###       
                                       xaapro_aminopeptidase	#.###       	#.###       
                                       zinc_carboxypeptidase	#.###       	#.###       
------------------------------------------------------------------------------------------------------------------</code></pre>

## FuncSanity type file - Peptidase Annotation

Peptidase predictions are incorporated into the **FuncSanity** pipeline, which allows users to provide additional information
about domain and membrane types. The default settings run searches for gram- bacteria, but users may also search for gram+ and archaea. 
This info for relevant genomes should be provided in a separate file and passed to `MetaSanity` from the command line using the `-t` flag. 
Pipeline searches can be run with any combination of gram+/- and bacteria/archaea. The format of this file should include 
the following info, separated by tabs, with one line per relevant fasta file passed to pipeline:

<pre><code>[fasta-file]\t[Bacteria/Archaea]\t[gram+/gram-]\n</code></pre> 
Example:
`example-fasta-file.fna\tArchaea\tgram+\n`

This file is only required if running the **peptidase** portion of the pipeline on non gram- bacteria.
    
## FuncSanity config file

The **FuncSanity** default config file allows for paths to calling programs to be set, as well as for program-level flags 
to be provided. Note that individual flags (e.g. those that are passed without arguments) are set using `FLAGS`. 

Users may select which portions of the **FuncSanity** pipeline that they wish to run. **FuncSanity** determines valid pipes
from the user-provided config file and builds its pipeline accordingly.

### Configuring a pipeline

The **FuncSanity** config file is divided by "pipes" representing available annotation steps. 
The docker config file sections come pre-populated with the proper path arguments, and should only be modified
with additional flags or by commenting out unwanted sections. 

- Location: `Examples/Config/FuncSanity.ini` or `Examples/Config/Docker/FuncSanity.ini`
<pre><code># Docker/FuncSanity.ini
# Default config file for running the FuncSanity pipeline
# DO NOT edit any PATH, DATA, or DATA_DICT variables
# Users are recommended to edit copies of this file only

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# The following pipes **MUST** be set

[PRODIGAL]
PATH = /usr/bin/prodigal
-p = meta
FLAGS = -m

[HMMSEARCH]
PATH = /usr/bin/hmmsearch
-T = 75

[HMMCONVERT]
PATH = /usr/bin/hmmconvert

[HMMPRESS]
PATH = /usr/bin/hmmpress

[BIOMETADB]
--db_name = Metagenomes
FLAGS = -s

[DIAMOND]
PATH = /usr/bin/diamond


# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# The following pipe sections may optionally be set
# Ensure that the entire pipe section is valid,
# or deleted/commented out, prior to running pipeline


# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Peptidase annotation

[CAZY]
DATA = /home/appuser/Peptidase/dbCAN-fam-HMMs.txt

[MEROPS]
DATA = /home/appuser/Peptidase/MEROPS.pfam.hmm
DATA_DICT = /home/appuser/Peptidase/merops-as-pfams.txt

# [SIGNALP]
# PATH = /home/appuser/signalp/signalp

# [PSORTB]
# PATH = /usr/bin/psortb

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# KEGG pathway annotation

[KOFAMSCAN]
PATH = /usr/bin/kofamscan
--cpu = 1

[BIODATA]
PATH = /home/appuser/BioData/KEGGDecoder

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# PROKKA

[PROKKA]
PATH = /usr/bin/prokka
FLAGS = --addgenes,--addmrna,--usegenus,--metagenome,--rnammer,--force
--evalue = 1e-10
--cpus = 1

# # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# # InterproScan

# [INTERPROSCAN]
# PATH = /usr/bin/interproscan
# # Do not remove this next flag
# --tempdir = /home/appuser/interpro_tmp
# --applications = TIGRFAM,SFLD,SMART,SUPERFAMILY,Pfam,ProDom,Hamap,CDD,PANTHER
# --cpu = 1
# FLAGS = --goterms,--iprlookup,--pathways

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# VirSorter

[VIRSORTER]
PATH = /home/appuser/virsorter-data
--db = 2
--ncpu = 1</code></pre>

- General Notes
    - Depending on the number of genomes, the completion time for this pipeline can vary from several hours to several days.
    - `BioData` requires a valid `pip` installation as well as a downloaded copy of the github repository.
    - As this script will create multiple tables in a **BioMetaDB** project, neither the flag `--table_name` nor `--alias`
     should be provided in the relevant section of the config script. 

### A note on flags

In general, program flags/arguments that filter or reduce output are supported, and thus can be provided in the user-passed
config file. **However, flags that change the output of individual programs may cause unsuspected issues, and thus are not
recommended.**
