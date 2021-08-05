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
# Remaining data
python ./download-data.py
mkdir -p build
mv databases build/
# Link checkm data
checkm data setRoot build/databases/checkm
# Prokka setup
conda install -y -c conda-forge -c bioconda prokka
# MetaSanity run script setup
python ./install.py -s download_metasanity,config_pull -t SourceCode -o build
sed -i "s/MetaSanity\/build\///" build/MetaSanity.py
