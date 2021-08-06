#!/bin/bash
set -e

CONDA=`which conda`
CONDA_BIN=`dirname $CONDA`
CURR_DIR="$(pwd)"

# Extract zipped files
cd psortb
if ! [ -d libpsortb-1.0 ]; then
  tar -xzf libpsortb-1.0.tar.gz
fi
if ! [ -d bio-tools-psort-all ]; then
  tar -xzf bio-tools-psort-all.3.0.6.tar.gz
fi

# Descend into library and build
cd libpsortb-1.0
./configure --prefix `pwd`/build
make
make install
ldconfig

# Move back to bio-tools and build
cd ../bio-tools-psort-all
echo -e "$CONDA_BIN\n$CONDA_BIN\n`dirname $(pwd)`" | perl Makefile.PL
make
make install

# Build blast databases
cd psort/conf/analysis/sclblast
./makedb.sh

# Return to base MetaSanity repo dir
cd "$CURR_DIR"

## Path and location variable set
# echo export PATH="$(pwd)"/psortb/bio-tools-psort-all/psort/bin:'$PATH' >> ~/.bashrc
# echo export PSORT_ROOT="$(pwd)"/psortb >> ~/.bashrc
# echo export BLASTDIR="$CONDA_BIN" >> ~/.bashrc
# echo export PSORT_PFTOOLS="$CONDA_BIN" >> ~/.bashrc