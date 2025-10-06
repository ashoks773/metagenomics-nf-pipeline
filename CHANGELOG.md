# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-10-06

### Added
- Initial release of comprehensive metagenomic analysis pipeline
- Quality control with FastQC and MultiQC
- Read preprocessing with KneadData
- Taxonomic profiling with MetaPhlAn4
- Functional profiling with HUMAnN3
- Metagenomic assembly with MEGAHIT and SPAdes
- Gene prediction with Prodigal
- Genome binning with MetaBAT2, MaxBin2, and CONCOCT
- Bin integration with DAS_Tool
- Bin quality assessment with CheckM
- Bacterial growth rate calculation with DEMIC
- Functional annotation with KEGG and CAZy
- Support for Docker, Singularity, and Conda
- Support for SLURM HPC and AWS Batch execution
- Comprehensive documentation and examples

### Features
- Modular design allowing selective step execution
- Individual and co-assembly strategies
- Multiple binning tool integration
- Automatic error handling and retry logic
- Resume capability for interrupted runs
- Resource optimization with dynamic scaling

[1.0.0]: https://github.com/yourusername/metagenomics-nf-pipeline/releases/tag/v1.0.0
