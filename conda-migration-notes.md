# Update to MetaSanity installation v1.3.0

The following document is intended to provide a high-level overview of the differences in the conda installation available for MetaSanity v1.3.0.

In this update, the Docker or SourceCode installations remain unchanged.

## Installation
For the conda installation, users will pull the repo and run the installation script from within their conda `(base)` environment:

```shell
git clone https://github.com/cjneely10/MetaSanity.git
cd MetaSanity
conda env create -f environment.yml
./conda-install.sh
```

The `pipedm.py` path is manually updated to match the user's likely system pathing.

### Installation location
The `conda-install.sh` script generates a `build` directory to house the downloaded database files, config files, and the user-specific `MetaSanity.py` script.

Should the install script fail at any virsorter db setup, comment out line and re-run setup script. User will need to manually download data via the virsorter documentation.

## Compatibility
The conda installation does not include PSortB installed by default. It provides (most of) the dependencies needed for users who have it installed locally.

We provide a helper script `psortb-install.sh`, but it would need to be run using `sudo`, so we advise users to request help from their sysadmin prior to running.

## Usage
No changes are made to the usage of the program - users will continue to edit the `MetaSanity.py` script for third-party software, and will use this script to call the program.
