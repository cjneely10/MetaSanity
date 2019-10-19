# FuncSanity

## About

**FuncSanity** uses Prodigal, kofamscan, InterProScan, Prokka, VirSorter, PSORTb, SignalP, and KEGG-Decoder to structurally and functionally annotate contig data. This will generate a final **BioMetaDB** project containing integrated 
results of this pipeline. Users have the option of using prodigal gene calls or PROKKA-annotated gene calls in downstream analysis.

- Required arguments
    - --directory (-d): directory of fasta files
    - --config_file (-c): config.ini file matching template in Sample/Config
- Optional flags
    - --prokka (-p): Use prokka gene calls in downstream analysis
    - --cancel_autocommit (-a): Cancel creation/update of **BioMetaDB** project
- Optional arguments
    - --output_directory (-o): Output prefix
    - --biometadb_project (-b): Name to assign to **BioMetaDB** project, or name of existing project to use
    - --type_file (-t): type_file, formatted as `'file_name.fna\t[Archaea/Bacteria]\t[gram+/gram-]\n'`
        - This argument is only required if running the **peptidase** portion of the pipeline on non gram- bacteria.

## Example

- `MetaSanity FuncSanity -d fasta_folder/ -c metagenome_annotation.ini -o annot 2>annot.err`
- This command will use the fasta files in `fasta_folder/` in the annotation pipeline. It will output to the folder
`annot` and will use the config file entitled `metagenome_annotation.ini` to name the output database and to determine 
individual program arguments. Debugging and error messages will be saved to `annot.err`.
- This pipeline will generate a series of tables - a summary table, whose name is user-provided in the config file, as 
well as an individual table for each genome provided that describes annotations for each protein sequence identified
from the starting contigs.

Below is an example of an annotations database table that was generated for the genome of TOBG-CPC-51.

- View the summary table using `dbdm SUMMARIZE -c Metagenomes/ -t tobg-cpc-51`

<pre><code>SUMMARIZE: View summary of all tables in database
 Project root directory:  Metagenomes
 Name of database:    Metagenomes.db

**********************************************************************************************
          Table Name: tobg-cpc-51 
  Number of Records:        4167/4167      

             Database Average               Std Dev     

  num_phage_contigs_1 0.000                 0.000       
  num_phage_contigs_2 0.001                 0.046       
  num_phage_contigs_3 0.000                 0.000       
      num_prophages_1 0.000                 0.000       
      num_prophages_2 0.000                 0.000       
      num_prophages_3 0.000                 0.000       
----------------------------------------------------------------------------------------------

          Database  Most Frequent         Number      Total Count 

              cazy  GT41                  23          106         
  is_extracellular  False                 1715        1746        
                ko  K08884                25          1387        
       merops_pfam  PF00082               9           132         
            prokka  atsA_12               19          567         
-------------------------------------------------------------------------------------------</code></pre>

This is an excerpt of the table summarizing putative metabolic functions and raw peptidase counts for the entire genome set. Large sections of it have been omitted below.

- View the summary table using `dbdm SUMMARIZE -c Metagenomes/ -t functions`

<pre><code>SUMMARIZE: View summary of all tables in database
 Project root directory:  Metagenomes
 Name of database:    Metagenomes.db

*******************************************************************************************************************************************
                                                Table Name: functions   
    Number of Records:                                      10/10        

                                                  Database  Average               Std Dev     

                                                  adhesion  0.000                 0.000       
                                           alcohol_oxidase  0.000                 0.000       
                                              alphaamylase  0.000                 0.000       
                           alt_thiosulfate_oxidation_doxad  0.000                 0.000       
                            alt_thiosulfate_oxidation_tsda  0.100                 0.316       
                                          aminopeptidase_n  0.400                 0.516       
                                 ammonia_oxidation_amopmmo  0.000                 0.000       
                                         anaplerotic_genes  0.475                 0.275       
                          anoxygenic_typei_reaction_center  0.000                 0.000       
                         anoxygenic_typeii_reaction_center  0.000                 0.000       
                                         arsenic_reduction  0.250                 0.264       
                   bacterial_prepeptidase_cterminal_domain  0.000                 0.000       
                                     basic_endochitinase_b  0.000                 0.000       
                            betacarotene_1515monooxygenase  0.300                 0.483       
                                           betaglucosidase  0.100                 0.316       
                                 betanacetylhexosaminidase  0.300                 0.483       
                            bifunctional_chitinaselysozyme  0.000                 0.000       
                             biofilm_pga_synthesis_protein  0.000                 0.000       
                                    biofilm_regulator_bsss  0.000                 0.000              
                                                       ce6  0.200                 0.422       
                                                       ce7  0.300                 0.483       
                                                       ce9  1.200                 1.033       
                                                 cellulase  0.000                 0.000       
                                                chemotaxis  0.187                 0.314       
                                                 chitinase  0.700                 0.483       
                                        clostripain_family  0.100                 0.316       
                                    cobalamin_biosynthesis  0.146                 0.082       
                         coenzyme_bcoenzyme_m_regeneration  0.040                 0.084       
                           dissimilatory_sulfite___sulfide  0.000                 0.000       
                                         dms_dehydrogenase  0.000                 0.000       
                                            dmso_reductase  0.000                 0.000       
                                        dmsp_demethylation  0.000                 0.000       
                                      dmsp_lyase_dddlqpdkw  0.000                 0.000       
                                        dmsp_synthase_dsyb  0.200                 0.422       
                                                      dnra  0.200                 0.422       
                      dsrd_dissimilatory_sulfite_reductase  0.000                 0.000       
                                   entnerdoudoroff_pathway  0.475                 0.249       
                             exopolyalphagalacturonosidase  0.000                 0.000       
                                      exopolygalacturonase  0.000                 0.000       
                                    ferredoxin_hydrogenase  0.000                 0.000       
                                 ferrioxamine_biosynthesis  0.225                 0.079       
                                                 flagellum  0.513                 0.399       
                     fourhydroxybutyrate3hydroxypropionate  0.190                 0.110       
                                              ftype_atpase  0.912                 0.132       
                                                   g02null  0.100                 0.316           
                                                      gh65  0.100                 0.316       
                                                      gh74  1.900                 3.071       
                                                      gh77  0.500                 0.527       
                                                       gh8  0.100                 0.316       
                                                      gh81  0.300                 0.483       
                                                      gh88  0.200                 0.422       
                                                       gh9  0.300                 0.483       
                                                      gh93  0.600                 0.843       
                                                      gh94  0.000                 0.000       
                                                      gh95  0.100                 0.316       
                                                      gh99  0.100                 0.316       
                                              glucoamylase  0.000                 0.000       
                                           gluconeogenesis  0.424                 0.371       
                                                glycolysis  0.625                 0.095       
                                          glyoxylate_shunt  0.200                 0.422             
                                   hydrazine_dehydrogenase  0.000                 0.000       
                                        hydrazine_synthase  0.000                 0.000       
                            hydrogenquinone_oxidoreductase  0.000                 0.000       
                                   hydroxylamine_oxidation  0.000                 0.000         
                                                    n4null  0.100                 0.316       
                                                    n6null  0.600                 0.516       
                                nadhquinone_oxidoreductase  0.434                 0.346       
                               nadphquinone_oxidoreductase  0.000                 0.000       
                                  nadpreducing_hydrogenase  0.000                 0.000       
                                   nadreducing_hydrogenase  0.000                 0.000       
                     naphthalene_degradation_to_salicylate  0.000                 0.000       
                                          nife_hydrogenase  0.000                 0.000       
                                     nife_hydrogenase_hyd1  0.000                 0.000       
                                    nitric_oxide_reduction  0.000                 0.000       
                                         nitrite_oxidation  0.200                 0.422       
                                         nitrite_reduction  0.000                 0.000       
                                         nitrogen_fixation  0.000                 0.000       
                                    nitrousoxide_reduction  0.100                 0.316       
                                      oligoendopeptidase_f  0.800                 0.422       
                                  oligogalacturonide_lyase  0.000                 0.000       
                                                    p1null  0.300                 0.675       
                                            pectinesterase  0.000                 0.000       
                                      peptidase_family_c25  0.300                 0.483       
                                      peptidase_family_m28  1.000                 0.000       
                                      peptidase_family_m50  1.000                 0.000       
                      peptidase_propeptide_and_ypeb_domain  0.000                 0.000       
                                         peptidase_s24like  0.000                 0.000       
                                             peptidase_s26  0.000                 0.000       
                            phosphoserine_aminotransferase  1.000                 0.000       
                                             photosystem_i  0.000                 0.000       
                                            photosystem_ii  0.000                 0.000             
                                               pullulanase  0.000                 0.000       
                                      retinal_biosynthesis  0.300                 0.230       
                                                 rhodopsin  0.300                 0.483       
                                   riboflavin_biosynthesis  0.925                 0.121       
                                                rtca_cycle  0.000                 0.000       
                                                   rubisco  0.000                 0.000              
                                                    secsrp  0.639                 0.338              
                                       transporter_ammonia  0.300                 0.483       
                                     transporter_phosphate  0.700                 0.483       
                                   transporter_phosphonate  0.198                 0.417       
                                       transporter_thiamin  0.033                 0.104       
                                          transporter_urea  0.020                 0.063       
                                   transporter_vitamin_b12  0.000                 0.000       
                                   twin_arginine_targeting  0.500                 0.000       
                                          type_i_secretion  0.033                 0.104       
                                         type_ii_secretion  0.377                 0.067       
                                        type_iii_secretion  0.007                 0.021       
                                         type_iv_secretion  0.017                 0.035       
                                       type_vabc_secretion  0.000                 0.000       
                                         type_vi_secretion  0.000                 0.000       
                                                   u32null  0.300                 0.483       
                                                   u62null  0.700                 1.160       
                                                   u73null  0.700                 0.823       
                           ubiquinolcytochrome_c_reductase  0.000                 0.000       
                                  vanadiumonly_nitrogenase  0.000                 0.000       
                                              vtype_atpase  0.000                 0.000       
                                             woodljungdahl  0.017                 0.054       
                                     xaapro_aminopeptidase  1.000                 0.000       
                                     zinc_carboxypeptidase  0.800                 0.422       
-------------------------------------------------------------------------------------------------------------------------------------------</code></pre>

## FuncSanity type file

The default settings run searches for gram negative bacteria, but users may also search for gram positive bacteria and archaea. 
This info for relevant genomes should be provided in a separate file and passed to `MetaSanity` from the command line using the `-t` flag. 
Pipeline searches can be run with any combination of gram +/- bacteria/archaea. The format of this file should include 
the following info, separated by tabs, with one line per relevant fasta file passed to pipeline:

<pre><code>[fasta-file]\t[Bacteria/Archaea]\t[gram+/gram-]\n</code></pre> 
Example:
`example-fasta-file.fna\tArchaea\tgram+\n`
    
## FuncSanity config file

The **FuncSanity** default config file allows for program-level flags to be provided. Note that individual flags (e.g. those that are passed without arguments) are set using `FLAGS`. 

Users may select which portions of the **FuncSanity** pipeline that they wish to run. **FuncSanity** determines valid pipes
from un-commented sections of the user-provided config file and builds its pipeline accordingly.

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

### A note on flags

In general, program flags/arguments that filter or reduce output are supported, and thus can be provided in the user-passed
config file. **However, flags that change the output of individual programs may cause unsuspected issues, and thus are not
recommended.**
