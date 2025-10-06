# Comprehensive Metagenomic Analysis Pipeline

A complete Nextflow pipeline for metagenomic data analysis from raw reads to functional/taxonomic annotation and bacterial growth rate calculation.

## Overview

This pipeline integrates industry-standard tools to provide a complete workflow for metagenomic data analysis:

1. **Quality Control**: FastQC, MultiQC
2. **Preprocessing**: KneadData (quality filtering + host removal)
3. **Taxonomic Profiling**: MetaPhlAn4
4. **Functional Profiling**: HUMAnN3
5. **Assembly**: MEGAHIT or SPAdes
6. **Gene Prediction**: Prodigal
7. **Gene Quantification**: BWA + SAMtools
8. **Gene Clustering**: CD-HIT
9. **Functional Annotation**: KEGG, CAZy, ARDB
10. **Genome Binning**: MetaBAT2, MaxBin2, CONCOCT, DAS_Tool
11. **Bin Quality**: CheckM
12. **Growth Rates**: DEMIC

## Quick Start

### 1. Install Nextflow

```bash
curl -s https://get.nextflow.io | bash
mv nextflow /usr/local/bin/
```

### 2. Prepare Input Samplesheet

Create a CSV file (`samplesheet.csv`) with your samples:

```csv
sample,fastq_1,fastq_2
sample1,/path/to/sample1_R1.fastq.gz,/path/to/sample1_R2.fastq.gz
sample2,/path/to/sample2_R1.fastq.gz,/path/to/sample2_R2.fastq.gz
sample3,/path/to/sample3_R1.fastq.gz,/path/to/sample3_R2.fastq.gz
```

### 3. Download Required Databases

```bash
# MetaPhlAn database
metaphlan --install --bowtie2db /path/to/metaphlan_db

# HUMAnN databases
humann_databases --download chocophlan full /path/to/humann_dbs --update-config yes
humann_databases --download uniref uniref90_diamond /path/to/humann_dbs --update-config yes

# CheckM database
mkdir -p /path/to/checkm_data
cd /path/to/checkm_data
wget https://data.ace.uq.edu.au/public/CheckM_databases/checkm_data_2015_01_16.tar.gz
tar -xzf checkm_data_2015_01_16.tar.gz
checkm data setRoot /path/to/checkm_data

# Host genome (e.g., human GRCh38)
wget http://ftp.ensembl.org/pub/release-109/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
gunzip Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
bowtie2-build Homo_sapiens.GRCh38.dna.primary_assembly.fa human_GRCh38
```

### 4. Run the Pipeline

#### Option A: Local execution with Docker

```bash
nextflow run main.nf \
  --input samplesheet.csv \
  --outdir results \
  --host_genome /path/to/host_genome \
  --metaphlan_db /path/to/metaphlan_db \
  --humann_nucleotide_db /path/to/chocophlan \
  --humann_protein_db /path/to/uniref90_diamond \
  --checkm_db /path/to/checkm_data \
  -profile docker
```

#### Option B: HPC with SLURM

```bash
nextflow run main.nf \
  --input samplesheet.csv \
  --outdir results \
  --host_genome /path/to/host_genome \
  --metaphlan_db /path/to/metaphlan_db \
  --humann_nucleotide_db /path/to/chocophlan \
  --humann_protein_db /path/to/uniref90_diamond \
  --checkm_db /path/to/checkm_data \
  --kegg_db /path/to/kegg_db \
  --cazy_db /path/to/cazy_db \
  -profile slurm
```

#### Option C: AWS Batch

```bash
nextflow run main.nf \
  --input s3://bucket/samplesheet.csv \
  --outdir s3://bucket/results \
  --host_genome s3://bucket/databases/host_genome \
  --metaphlan_db s3://bucket/databases/metaphlan_db \
  --humann_nucleotide_db s3://bucket/databases/chocophlan \
  --humann_protein_db s3://bucket/databases/uniref90 \
  -profile awsbatch \
  -work-dir s3://bucket/work
```

## Pipeline Parameters

### Required Parameters

| Parameter | Description |
|-----------|-------------|
| `--input` | Path to samplesheet CSV file |
| `--outdir` | Output directory for results |

### Database Parameters

| Parameter | Description |
|-----------|-------------|
| `--host_genome` | Path to host genome for decontamination (optional) |
| `--metaphlan_db` | Path to MetaPhlAn database |
| `--humann_protein_db` | Path to HUMAnN protein database |
| `--humann_nucleotide_db` | Path to HUMAnN nucleotide database |
| `--checkm_db` | Path to CheckM database |
| `--kegg_db` | Path to KEGG database (for BLAST) |
| `--cazy_db` | Path to CAZy database |
| `--ardb_db` | Path to ARDB database |

### Pipeline Control Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--skip_qc` | false | Skip FastQC quality control |
| `--skip_kneaddata` | false | Skip KneadData preprocessing |
| `--skip_assembly` | false | Skip assembly step |
| `--skip_binning` | false | Skip genome binning |
| `--skip_growth_rates` | false | Skip growth rate calculation |
| `--skip_functional` | false | Skip functional annotation |
| `--skip_taxonomic` | false | Skip taxonomic profiling |

### Assembly Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--assembler` | megahit | Assembly tool: 'megahit' or 'spades' |
| `--coassembly` | false | Perform co-assembly of all samples |
| `--min_contig_length` | 1000 | Minimum contig length to keep |

### Binning Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--binning_tools` | metabat2,maxbin2 | Binning tools (comma-separated) |
| `--min_bin_completeness` | 50 | Minimum bin completeness (%) |
| `--max_bin_contamination` | 10 | Maximum bin contamination (%) |

### Resource Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--max_cpus` | 16 | Maximum CPUs per process |
| `--max_memory` | 128.GB | Maximum memory per process |
| `--max_time` | 240.h | Maximum time per process |

## Output Structure

```
results/
├── 01_kneaddata/              # Quality-filtered reads
│   ├── sample1/
│   ├── sample2/
│   └── ...
├── 02_taxonomy/               # Taxonomic profiles
│   └── metaphlan/
│       ├── sample1/
│       └── ...
├── 03_functional/             # Functional profiles
│   └── humann/
│       ├── sample1/
│       └── ...
├── 04_assembly/               # Assembled contigs
│   ├── megahit/
│   └── filtered_contigs/
├── 05_gene_prediction/        # Predicted genes
│   └── prodigal/
├── 06_gene_quantification/    # Gene abundance
│   └── bwa/
├── 07_nr_genes/               # Non-redundant gene catalog
│   └── cdhit/
├── 08_functional_annotation/  # Gene annotations
│   ├── kegg/
│   ├── cazy/
│   └── ardb/
├── 09_binning/                # MAGs (bins)
│   ├── metabat2/
│   ├── maxbin2/
│   ├── dastool/
│   └── checkm/
├── 10_growth_rates/           # Bacterial growth rates
│   └── demic/
├── qc/                        # Quality control reports
│   ├── fastqc/
│   └── multiqc/
└── pipeline_info/             # Pipeline execution info
    ├── execution_report.html
    ├── execution_timeline.html
    ├── execution_trace.txt
    └── pipeline_dag.svg
```

## Profiles

### Docker

Uses Docker containers for all processes. Suitable for local execution.

```bash
nextflow run main.nf -profile docker [other options]
```

### Singularity

Uses Singularity containers. Ideal for HPC environments.

```bash
nextflow run main.nf -profile singularity [other options]
```

### Conda

Uses Conda environments for each process.

```bash
nextflow run main.nf -profile conda [other options]
```

### SLURM

Configured for SLURM HPC clusters with Singularity.

```bash
nextflow run main.nf -profile slurm [other options]
```

### AWS Batch

Configured for AWS Batch execution.

```bash
nextflow run main.nf -profile awsbatch [other options]
```

## Advanced Usage

### Running Specific Modules

```bash
# Only taxonomic and functional profiling (skip assembly)
nextflow run main.nf \
  --input samplesheet.csv \
  --outdir results \
  --skip_assembly \
  --skip_binning \
  --skip_growth_rates \
  -profile docker

# Only assembly and binning
nextflow run main.nf \
  --input samplesheet.csv \
  --outdir results \
  --skip_taxonomic \
  --skip_functional \
  -profile docker
```

### Co-assembly Mode

```bash
# Perform co-assembly instead of individual assemblies
nextflow run main.nf \
  --input samplesheet.csv \
  --outdir results \
  --coassembly \
  -profile docker
```

### Custom Resource Allocation

```bash
# Adjust maximum resources
nextflow run main.nf \
  --input samplesheet.csv \
  --outdir results \
  --max_cpus 32 \
  --max_memory 256.GB \
  --max_time 480.h \
  -profile slurm
```

## Troubleshooting

### Common Issues

#### 1. Out of Memory Errors

Increase memory allocation:
```bash
nextflow run main.nf --max_memory 256.GB [other options]
```

#### 2. Timeout Errors

Increase time limit:
```bash
nextflow run main.nf --max_time 480.h [other options]
```

#### 3. Database Not Found

Ensure all database paths are absolute and exist:
```bash
ls -l /path/to/metaphlan_db
ls -l /path/to/humann_dbs
```

### Resume Failed Runs

Nextflow automatically caches completed processes. Resume with:

```bash
nextflow run main.nf [options] -resume
```

## Citation

If you use this pipeline, please cite:

- **Nextflow**: Di Tommaso, P., et al. (2017). Nextflow enables reproducible computational workflows. Nature Biotechnology.
- **KneadData**: https://huttenhower.sph.harvard.edu/kneaddata/
- **MetaPhlAn4**: Blanco-Míguez, A., et al. (2023). Extending and improving metagenomic taxonomic profiling with uncharacterized species using MetaPhlAn 4. Nature Biotechnology.
- **HUMAnN3**: Beghini, F., et al. (2021). Integrating taxonomic, functional, and strain-level profiling of diverse microbial communities with bioBakery 3. eLife.
- **MEGAHIT**: Li, D., et al. (2015). MEGAHIT: an ultra-fast single-node solution for large and complex metagenomics assembly via succinct de Bruijn graph. Bioinformatics.
- **MetaBAT2**: Kang, D.D., et al. (2019). MetaBAT 2: an adaptive binning algorithm for robust and efficient genome reconstruction from metagenome assemblies. PeerJ.
- **CheckM**: Parks, D.H., et al. (2015). CheckM: assessing the quality of microbial genomes recovered from isolates, single cells, and metagenomes. Genome Research.
- **DEMIC**: Korem, T., et al. (2015). Growth dynamics of gut microbiota in health and disease inferred from single metagenomic samples. Science.

## Contact

For questions or issues:
- GitHub Issues: https://github.com/ashoks773/metagenomics-nf-pipeline
- Email: ashoks773@gmail.com OR compbiosharma@gmail.com

## License

MIT License

## Acknowledgments

Based on workflows developed by Ashok K. Sharma:
- https://github.com/ashoks773/Bacterial_growth_rates
- https://github.com/ashoks773/Primates-Gut-Metagenome
