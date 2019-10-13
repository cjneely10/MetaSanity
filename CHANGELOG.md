# Changelog
All notable changes to this **MetaSanity** and **BioMetaDB** will be documented in this file.

## MetaSanity v1.1 - 10/14/2019
### Added
- Speed up **BioMetaDB** runs for hundreds of genomes.
- Incorporate tRNA/rRNA data in Prokka annotations.
- Include gene description in annotations.
- Determine high/medium/low quality genomes by incorporating Prokka annotations.

### Changed
- Update `install.py`
    - Download Source Code or Docker version via this script.
    - Auto-install package to download directory.
    
### Fixed
- Correctly parses evaluation metrics for very low-quality genomes.

## MetaSanity v1 - 10/01/2019
First Release


