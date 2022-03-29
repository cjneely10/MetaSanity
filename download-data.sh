#!/bin/bash
set -eu

WGET="$(which wget)"
DOWNLOAD_DIR="databases"

# Confirm `wget` is available to use
if [ ! -e "$WGET" ]; then
  echo "Error locating 'wget' installation"
  exit 1
fi

mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

# Helper function - mkdir, cd, wget
function download() {
  mkdir -p "$1"
  cd "$1"
  "$WGET" "$2" -O "$3"
}

## Download and extract each set of required data

# GTDB-Tk
download gtdbtk https://data.ace.uq.edu.au/public/gtdb/data/releases/latest/auxillary_files/gtdbtk_data.tar.gz gtdbtk_r95_data.tar.gz
tar -xzf gtdbtk_r95_data.tar.gz
cd ..

# CheckM
download checkm https://data.ace.uq.edu.au/public/CheckM_databases/checkm_data_2015_01_16.tar.gz
tar -xzf checkm_data_2015_01_16.tar.gz
cd ..

# MEROPS
download peptidase https://www.dropbox.com/s/8pskp3hlkdnt6zm/MEROPS.pfam.hmm?dl=1 MEROPS.pfam.hmm
cd ..

# MEROPS as PFAM
download peptidase https://raw.githubusercontent.com/cjneely10/MetaSanity/master/Sample/Data/merops-as-pfams.txt merops-as-pfams.txt
cd ..

# CAZy
download peptidase http://bcb.unl.edu/dbCAN2/download/dbCAN-HMMdb-V8.txt dbCAN-HMMdb-V8.txt
ln -s dbCAN-HMMdb-V8.txt dbCAN-fam-HMMs.txt
cd ..

# KofamScan profiles
download kofamscan ftp://ftp.genome.jp/pub/db/kofam/profiles.tar.gz profiles.tar.gz
tar -xzf profiles.tar.gz
cd ..

# KofamScan list
download kofamscan ftp://ftp.genome.jp/pub/db/kofam/ko_list.gz ko_list.gz
gunzip ko_list.gz
cd ..
