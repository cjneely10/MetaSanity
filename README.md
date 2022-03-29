# MetaSanity v1.3

## About

**MetaSanity v1.3** provides a unified workflow for genome assessment and functional annotation that combines
all outputs into a single queryable database.

---
Looking to annotate large numbers of eukaryotic genomes or MAGs? Check out [EukMetaSanity](https://github.com/cjneely10/EukMetaSanity)!

---

### [Installing MetaSanity](https://github.com/cjneely10/MetaSanity/wiki/2-Installation-Conda)
MetaSanity is installable through Conda.
See the [wiki page](https://github.com/cjneely10/MetaSanity/wiki/2-Installation-Conda) for complete installation instructions.

### [PhyloSanity](https://github.com/cjneely10/MetaSanity/wiki/4-PhyloSanity)
Evaluate MAGs for completion and contamination using CheckM, and evaluate redundancy using FastANI. Optionally predict phylogeny using GTDB-Tk.

### [FuncSanity](https://github.com/cjneely10/MetaSanity/wiki/5-FuncSanity)
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

## Citations

**MetaSanity** would not be possible without the open-source contributions of several research teams. Please include the following citations
when using **MetaSanity**:

Neely C., Graham E. D., Tully, B. J. (2020). MetaSanity: An integrated, customizable microbial genome evaluation and annotation pipeline. Bioinformatics, Volume 36, Issue 15, 1 August 2020, Pages 4341–4344, https://doi.org/10.1093/bioinformatics/btaa512

Aramaki T., Blanc-Mathieu R., Endo H., Ohkubo K., Kanehisa M., Goto S., Ogata H. (2019). KofamKOALA: KEGG ortholog assignment based on profile HMM and adaptive score threshold. bioRxiv doi: https://doi.org/10.1101/602110. 

Bayer, M. (2012). SQLAlchemy. In Amy Brown and Greg Wilson, editors, “The Architecture of Open Source Applications Volume II: Structure, Scale, and a Few More Fearless Hacks.” http://aosabook.org. 

Bradshaw, R., Behnel S., Seljebotn D.S., Ewing, G., et al. (2011). The Cython compiler. http://cython.org. 

Buchfink B., Xie C., Huson D. H. (2015). Fast and sensitive protein alignment using DIAMOND. Nature Methods 12, 59-60. doi:10.1038/nmeth.3176. 

Camacho C., Coulouris G., Avagyan V., Ma N., Papadopoulos J., Bealer K., & Madden T.L. (2008) "BLAST+: architecture and applications." BMC Bioinformatics 10:421 https://bmcbioinformatics.biomedcentral.com/articles/10.1186/1471-2105-10-421. 

Cantarel, B. L., Coutinho, P. M., Rancurel, C., Bernard, T., Lombard, V., & Henrissat, B. (2009). The Carbohydrate-Active EnZymes database (CAZy): an expert resource for Glycogenomics. Nucleic Acids Research, 37(Database), D233–D238. http://doi.org/10.1093/nar/gkn663. 

Eddy S.R. (2011) Accelerated Profile HMM Searches. PLoS Comput Biol 7(10): e1002195. https://doi.org/10.1371/journal.pcbi.1002195. 

Finn, R. D., Coggill, P., Eberhardt, R. Y., Eddy, S. R., Mistry, J., Mitchell, A. L., et al. (2016). The Pfam protein families database: towards a more sustainable future. Nucleic Acids Research, 44(D1), D279–D285. http://doi.org/10.1093/nar/gkv1344. 

Graham E. D., Heidelberg J. F., Tully B. J. (2018) Potential for primary productivity in a globally-distributed bacterial phototroph. ISME J 350, 1–6. 

Haft, D. H., Selengut, J. D., & White, O. (2003). The TIGRFAMs database of protein families. Nucleic Acids Research, 31(1), 371–373. http://doi.org/10.1093/nar/gkg128. 

Hyatt, D., Chen, G. L., Locascio, P. F., Land, M. L., Larimer, F. W., & Hauser, L. J. (2010). Prodigal: prokaryotic gene recognition and translation initiation site identification. BMC bioinformatics, 11, 119. doi:10.1186/1471-2105-11-119. 

ISO/IEC. (2014). ISO International Standard ISO/IEC 14882:2014(E) – Programming Language C++. [Working draft]. Geneva, Switzerland: International Organization for Standardization (ISO). Retrieved from https://isocpp.org/std/the-standard. 

Jain C., et al. 2019. High-throughput ANI Analysis of 90K Prokaryotic Genomes Reveals Clear Species Boundaries. Nature Communications, doi: 10.1038/s41467-018-07641-9. 

Jones, P., Binns, D., Chang, H. Y., Fraser, M., Li, W., McAnulla, C., … Hunter, S. (2014). InterProScan 5: genome-scale protein function classification. Bioinformatics (Oxford, England), 30(9), 1236–1240. doi:10.1093/bioinformatics/btu031. 

Lagesen, K., Hallin, P., Rødland, E. A., Staerfeldt, H. H., Rognes, T., & Ussery, D. W. (2007). RNAmmer: consistent and rapid annotation of ribosomal RNA genes. Nucleic acids research, 35(9), 3100–3108. doi:10.1093/nar/gkm160. 

Marchler-Bauer A., Bo Y., Han L., He J., Lanczycki C. J., Lu S., Chitsaz F., Derbyshire M. K., Geer R. C., Gonzales N. R., Gwadz M., Hurwitz D. I., Lu F., Marchler G. H., Song J. S., Thanki N., Wang Z., Yamashita R. A.,  

Matsen F. A., Kodner R. B., Armbrust E. V. (2010). pplacer: linear time maximum-likelihood and Bayesian phylogenetic placement of sequences onto a fixed reference tree. BMC Bioinformatics 11: doi:10.1186/1471-2105-11-538. 

Merkel, D. (2014). Docker: Lightweight Linux Containers for Consistent Development and Deployment. Linux J. 

Mi, H., Muruganujan, A., Huang, X., Ebert, D., Mills, C., Guo, X., & Thomas, P. D. (2019). Protocol Update for large-scale genome and gene function analysis with the PANTHER classification system (v.14.0). Nature Protocols, 1–21. http://doi.org/10.1038/s41596-019-0128-8. 

Nielsen H. (2017) Predicting Secretory Proteins with SignalP. In: Kihara D. (eds) Protein Function Prediction. Methods in Molecular Biology, vol 1611. Humana Press, New York, NY. 

Parks, D. H., Chuvochina, M., Waite, D. W., Rinke, C., Skarshewski, A., Chaumeil, P.-A., & Hugenholtz, P. (2018). A standardized bacterial taxonomy based on genome phylogeny substantially revises the tree of life. Nature Biotechnology, 15, 1–14. http://doi.org/10.1038/nbt.4229. 

Parks, D. H., Imelfort M., Skennerton C. T., Hugenholtz P., Tyson G. W. (2015). CheckM: assessing the quality of microbial genomes recovered from isolates, single cells, and metagenomes. Genome Research, 25: 1043–1055. 

Python Software Foundation. Python Language Reference, version 3. http://www.python.org 

Rawlings, N. D., Waller, M., Barrett, A. J., & Bateman, A. (2013). MEROPS: the database of proteolytic enzymes, their substrates and inhibitors. Nucleic Acids Research, 42(D1), D503–D509. http://doi.org/10.1093/nar/gkt953. 

Roux, S., Enault, F., Hurwitz, B. L., & Sullivan, M. B. (2015). VirSorter: mining viral signal from microbial genomic data. PeerJ, 3, e985. https://doi.org/10.7717/peerj.985. 

Seemann T. (2014). Prokka: rapid prokaryotic genome annotation. Bioinformatics 30(14), 2068-9. PMID:24642063. 

Stepanauskas, R., Fergusson, E. A., Brown, J., Poulton, N. J., Ben Tupper, Labonté, J. M., et al. (2017). Improved genome recovery and integrated cell-size analyses of individual uncultured microbial cells and viral particles. Nature Communications, 8(1), 1–10. http://doi.org/10.1038/s41467-017-00128-z. 

Thrash, J. C., Weckhorst, J. L., & Pitre, D. M. (2015). Cultivating Fastidious Microbes. In Hydrocarbon and Lipid Microbiology Protocols (Vol. 39, pp. 57–78). Berlin, Heidelberg: Springer Berlin Heidelberg. http://doi.org/10.1007/8623_2015_67. 

Tully, B. J. (2019). Metabolic diversity within the globally abundant Marine Group II Euryarchaea offers insight into ecological patterns. Nature Communications, 10(1), 1–12. http://doi.org/10.1038/s41467-018-07840-4. 

Tully, B. J., Graham, E. D., & Heidelberg, J. F. (2018). The reconstruction of 2,631 draft metagenome-assembled genomes from the global oceans. Scientific Data, 5, 170203. http://doi.org/10.1038/sdata.2017.203. 

Yu, N. Y., Wagner, J. R., Laird, M. R., Melli, G., Rey, S., Lo, R., Dao, P., Sahinalp, S. C., Ester, M., Foster, L.J., and Brinkman, F. S. L. (2010). PSORTb 3.0: improved protein subcellular localization prediction with refined localization subcategories and predictive capabilities for all prokaryotes. Bioinformatics 26(13):1608-1615. 

Zhang D., Zheng C., Geer L. Y., Bryant S. H. (2017). CDD/SPARCLE: functional classification of proteins via subfamily domain architectures. Nucleic Acids Research 45(D1): D200-D203. doi: 10.1093/nar/gkw1129. 

Zhang, H., Yohe, T., Huang, L., Entwistle, S., Wu, P., Yang, Z., et al. (2018). dbCAN2: a meta server for automated carbohydrate-active enzyme annotation. Nucleic Acids Research, 46(W1), W95–W101. http://doi.org/10.1093/nar/gky418. 
