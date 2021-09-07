#!/bin/bash
set -e

# Detect conda environment
CONDA="`which conda`"
CONDA_DIRNAME="`dirname "$CONDA"`"
MINICONDA="`dirname "$CONDA_DIRNAME"`"
SOURCE="$MINICONDA"/etc/profile.d/conda.sh
[ ! -f "$SOURCE" ] && (echo "Unable to locate conda installation directory" && exit 1)

# Load conda env with most dependencies present and activate
#conda env create -f environment.yml
source "$SOURCE"
conda activate MetaSanity

# Create build environment
mkdir -p build
if [ ! -e build/databases ]; then
  # Download remaining data and move to build
  python ./download-data.py -d checkm,gtdbtk,kofamscan,peptidase
  mv databases build/
fi

# Link checkm data
checkm data setRoot build/databases/checkm

# Link GTDB-Tk data
echo export GTDBTK_DATA_PATH="$(pwd)"/build/databases/gtdbtk/release202 >> ~/.bashrc

# VirSorter data
VIRSORTER_DATA_PATH=build/databases/virsorter
if [ -e $VIRSORTER_DATA_PATH ]; then
  rm -r $VIRSORTER_DATA_PATH
fi
virsorter setup -d $VIRSORTER_DATA_PATH -j 4

# Prokka setup
mamba install -y -c conda-forge -c bioconda prokka

# MetaSanity run script setup
python ./install.py -s download_metasanity,config_pull -t Conda -o build -v v1.3.0
# MetaSanity build
python setup.py build_ext --inplace
# Additional needed files and path updates
cp VERSIONS.json build/
# MetaSanity calling script path
sed -i "s/MetaSanity\/build\///" build/MetaSanity.py
# Config data/program paths edit
BUILD_PATH="$(pwd)"/build/databases/
sed -i "s,/path/to/,$BUILD_PATH,g" build/Config/Conda/*Sanity.ini
# Provide uid for docker users of virsorter
sed -i "s,UID-of-user-from-etc/passwd-file,$UID," build/Config/Conda/*FuncSanity.ini
echo "Your installation is complete"
