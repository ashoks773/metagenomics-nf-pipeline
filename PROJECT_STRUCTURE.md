# Complete Project Structure

This document describes the complete directory structure for the metagenomic pipeline.

## Directory Layout

```
metagenomics-pipeline/
├── main.nf                          # Main pipeline workflow
├── nextflow.config                  # Main configuration file
├── README.md                        # User documentation
├── SETUP.md                         # Installation and setup guide
├── PROJECT_STRUCTURE.md             # This file
├── LICENSE                          # License file (MIT)
├── .gitignore                       # Git ignore file
│
├── conf/                            # Configuration files
│   ├── base.config                  # Base resource configuration
│   ├── docker.config                # Docker-specific config
│   ├── singularity.config           # Singularity-specific config
│   ├── conda.config                 # Conda-specific config
│   ├── slurm.config                 # SLURM HPC config
│   ├── awsbatch.config              # AWS Batch config
│   └── test.config                  # Test dataset config
│
├── modules/                         # Process modules
│   ├── qc/
│   │   ├── fastqc.nf               # FastQC quality control
│   │   └── multiqc.nf              # MultiQC report aggregation
│   │
│   ├── preprocessing/
│   │   └── kneaddata.nf            # Quality filtering and host removal
│   │
│   ├── taxonomy/
│   │   └── metaphlan.nf            # Taxonomic profiling
│   │
│   ├── functional/
│   │   └── humann.nf               # Functional profiling
│   │
│   ├── assembly/
│   │   ├── megahit.nf              # MEGAHIT assembler
│   │   ├── spades.nf               # SPAdes assembler
│   │   └── filter_contigs.nf       # Contig filtering
│   │
│   ├── annotation/
│   │   ├── prodigal.nf             # Gene prediction
│   │   ├── kegg.nf                 # KEGG annotation
│   │   └── cazy.nf                 # CAZy annotation
│   │
│   ├── mapping/
│   │   ├── bwa.nf                  # BWA mapping (for genes)
│   │   ├── bowtie2.nf              # Bowtie2 mapping (for contigs)
│   │   └── samtools.nf             # SAMtools operations
│   │
│   ├── binning/
│   │   ├── metabat2.nf             # MetaBAT2 binning
│   │   ├── maxbin2.nf              # MaxBin2 binning
│   │   ├── concoct.nf              # CONCOCT binning
│   │   ├── dastool.nf              # DAS_Tool integration
│   │   └── checkm.nf               # CheckM quality assessment
│   │
│   ├── clustering/
│   │   └── cdhit.nf                # CD-HIT clustering
│   │
│   └── growth/
│       └── demic.nf                # DEMIC growth rate calculation
│
├── bin/                             # Custom scripts
│   ├── filter_bins_by_quality.py   # Filter bins by CheckM results
│   ├── summarize_taxonomy.R        # Summarize MetaPhlAn results
│   ├── summarize_functions.R       # Summarize HUMAnN results
│   ├── parse_kegg_results.py       # Parse KEGG annotations
│   └── plot_growth_rates.R         # Visualize growth rates
│
├── assets/                          # Static assets
│   ├── samplesheet_schema.json     # Schema for input validation
│   └── multiqc_config.yaml         # MultiQC configuration
│
├── docs/                            # Additional documentation
│   ├── usage.md                    # Detailed usage guide
│   ├── output.md                   # Output file descriptions
│   ├── parameters.md               # Parameter documentation
│   └── troubleshooting.md          # Common issues and solutions
│
├── test/                            # Test data and configs
│   ├── test_samplesheet.csv        # Test sample data
│   ├── test.config                 # Test configuration
│   └── data/                       # Small test datasets
│       ├── sample1_R1.fastq.gz
│       └── sample1_R2.fastq.gz
│
├── scripts/                         # Helper scripts
│   ├── run_pipeline.sh             # Quick start script
│   ├── setup_databases.sh          # Database download script
│   ├── validate_installation.sh    # Check dependencies
│   └── generate_samplesheet.py     # Create samplesheet from directory
│
└── workflows/                       # Sub-workflows (if needed)
    ├── assembly.nf                 # Assembly sub-workflow
    ├── annotation.nf               # Annotation sub-workflow
    └── binning.nf                  # Binning sub-workflow
```

## File Descriptions

### Main Files

- **main.nf**: The main Nextflow workflow that orchestrates all processes
- **nextflow.config**: Global configuration including profiles and resource limits
- **README.md**: User-facing documentation with quick start guide
- **SETUP.md**: Detailed installation and database setup instructions

### Configuration Files (conf/)

- **base.config**: Default resource requirements for all processes
- **docker.config**: Docker-specific settings
- **singularity.config**: Singularity container settings
- **conda.config**: Conda environment settings
- **slurm.config**: SLURM job scheduler configuration
- **awsbatch.config**: AWS Batch execution settings
- **test.config**: Small test dataset configuration

### Process Modules (modules/)

Each module is a self-contained Nextflow process with:
- Input/output definitions
- Container specifications
- Resource requirements
- Process-specific logic

### Helper Scripts (bin/)

Custom scripts called by processes:
- **filter_bins_by_quality.py**: Post-process CheckM results
- **summarize_taxonomy.R**: Aggregate and visualize taxonomic profiles
- **summarize_functions.R**: Aggregate and visualize functional profiles
- **parse_kegg_results.py**: Extract gene annotations from KEGG results
- **plot_growth_rates.R**: Visualize bacterial growth rates

### Pipeline Scripts (scripts/)

User-facing scripts:
- **run_pipeline.sh**: Interactive pipeline launcher
- **setup_databases.sh**: Automated database download
- **validate_installation.sh**: Check all dependencies
- **generate_samplesheet.py**: Auto-generate samplesheet from data directory

## Creating the Directory Structure

```bash
# Create main directories
mkdir -p metagenomics-pipeline/{conf,modules,bin,assets,docs,test,scripts,workflows}

# Create module subdirectories
cd metagenomics-pipeline/modules
mkdir -p qc preprocessing taxonomy functional assembly annotation mapping binning clustering growth

# Create test data directory
cd ../test
mkdir -p data

# Return to main directory
cd ..
```

## Adding Files to the Structure

1. **Main workflow**: Place `main.nf` in root
2. **Configurations**: Add config files to `conf/`
3. **Process modules**: Add `.nf` files to appropriate `modules/` subdirectories
4. **Helper scripts**: Add utility scripts to `bin/` and make executable
5. **Documentation**: Add markdown files to `docs/`
6. **Test data**: Add small test datasets to `test/data/`

## Example Samplesheet Format

Place in root or `test/` directory:

```csv
sample,fastq_1,fastq_2
sample1,/path/to/sample1_R1.fastq.gz,/path/to/sample1_R2.fastq.gz
sample2,/path/to/sample2_R1.fastq.gz,/path/to/sample2_R2.fastq.gz
```

## Git Repository Setup

```bash
# Initialize git
git init

# Create .gitignore
cat > .gitignore << 'EOF'
# Nextflow
work/
.nextflow/
.nextflow.log*
*.html
*.pdf
trace.txt
timeline.html
report.html

# Results
results/
test_results/

# Databases (too large for git)
databases/
*.dmnd
*.bt2
*.bt2l
*.bam
*.sam

# Python
__pycache__/
*.py[cod]
*$py.class
.Python
*.so

# R
.Rhistory
.RData
.Rproj.user

# System
.DS_Store
Thumbs.db
EOF

# Add files
git add .
git commit -m "Initial commit: Complete metagenomic pipeline"

# Add remote and push
git remote add origin https://github.com/yourusername/metagenomics-pipeline.git
git push -u origin main
```

## Running from Different Locations

### From Git Repository

```bash
# Clone repository
git clone https://github.com/yourusername/metagenomics-pipeline.git
cd metagenomics-pipeline

# Run pipeline
./scripts/run_pipeline.sh -i samples.csv -o results -d /path/to/databases -p docker
```

### Direct Nextflow Execution

```bash
# Run from GitHub (no clone needed)
nextflow run yourusername/metagenomics-pipeline \
    --input samples.csv \
    --outdir results \
    --metaphlan_db /path/to/metaphlan_db \
    -profile docker

# Run from local directory
nextflow run /path/to/metagenomics-pipeline/main.nf \
    --input samples.csv \
    --outdir results \
    -profile docker
```

## Output Directory Structure

After running the pipeline:

```
results/
├── 01_kneaddata/              # Cleaned reads
├── 02_taxonomy/               # Taxonomic profiles
├── 03_functional/             # Functional profiles
├── 04_assembly/               # Assembled contigs
├── 05_gene_prediction/        # Predicted genes
├── 06_gene_quantification/    # Gene abundance
├── 07_nr_genes/               # Non-redundant genes
├── 08_functional_annotation/  # Gene annotations
├── 09_binning/                # MAGs (bins)
├── 10_growth_rates/           # Growth rate estimates
├── qc/                        # Quality control reports
└── pipeline_info/             # Execution information
```

## Best Practices

1. **Version Control**: Use git tags for releases
2. **Documentation**: Keep README and docs up to date
3. **Testing**: Add test data for CI/CD
4. **Modularity**: Keep processes independent and reusable
5. **Configuration**: Use profiles for different environments
6. **Reproducibility**: Pin software versions in containers

## Contributing

To contribute to this pipeline:

1. Fork the repository
2. Create a feature branch
3. Make changes and test thoroughly
4. Submit a pull request with clear description
5. Ensure all tests pass

## Maintenance

### Regular Updates

- Update container versions
- Test with new software releases
- Update documentation
- Add new features based on user feedback

### Version Numbering

Follow semantic versioning (MAJOR.MINOR.PATCH):
- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes

### Release Checklist

- [ ] Update version in `nextflow.config`
- [ ] Update `CHANGELOG.md`
- [ ] Test all execution profiles
- [ ] Update documentation
- [ ] Create git tag
- [ ] Update container versions
