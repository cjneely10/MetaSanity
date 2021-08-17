# Update to MetaSanity installation v1.3.0

The following document is intended to provide a high-level overview of the differences in the conda installation available for MetaSanity v1.3.0.

In this update, the Docker or SourceCode installations remain unchanged.

## Installation
Ensure you have the conda package `mamba` installed in your `(base)` environment:

```shell
conda install mamba -n base -c conda-forge
```

For the conda installation, users will pull the repo and run the installation script from within their conda `(base)` environment:

```shell
git clone https://github.com/cjneely10/MetaSanity.git
cd MetaSanity
git checkout v1.3.0
mamba env create -f environment.yml
./conda-install.sh
```

The `MetaSanity.py` path is manually updated to match the user's likely system pathing. This will also automatically download required databases to the installation directory.

### Installation location
The `conda-install.sh` script generates a `build` directory to house the downloaded database files, config files, and the user-specific `MetaSanity.py` script. 
Database files are also downloaded here, so users will want to ensure that they have adequate storage space for ~120GB of data

Should the install script fail at the virsorter db setup, comment out line and re-run setup script. User will need to manually download data via the virsorter documentation.

## Compatibility
The conda installation does not include PSortB installed by default. It provides (most of) the dependencies needed for users who have it installed locally.

We provide a helper script `psortb-install.sh`, but it would need to be run using `sudo`, so we advise users to request help from their sysadmin prior to installation.
Users will also need to set the required environment variables that are listed at the bottom of the script.

All externally-downloaded programs remain supported with their respective versions.

## Usage
Almost no changes are made to the usage of the program - users will continue to edit the `MetaSanity.py` script for third-party software, and will use this script to call the program.

Prior to using MetaSanity, activate your conda environment:

```shell
conda activate MetaSanity
```

The `MetaSanity.py` script is available in the `build` directory:

```shell
/path/to/MetaSanity/build/MetaSanity.py [...] -c ... -d ...
```
