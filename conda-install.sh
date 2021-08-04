#!/bin/bash
set -e

# Detect conda environment
CONDA=`which conda`
CONDA_DIRNAME=`dirname $CONDA`
MINICONDA=`dirname $CONDA_DIRNAME`
SOURCE=$MINICONDA/etc/profile.d/conda.sh
[ ! -f $SOURCE ] && (echo "Unable to locate source directory" && exit 1)

# Create conda env and activate
conda env create -f environment.yml
source $SOURCE
conda activate MetaSanity
# GTDB-Tk data and finish install

# CheckM data and finish install

# PSortb setup
./psortb-install.sh
# Prokka setup
conda install -y -c conda-forge -c bioconda prokka
