# Pipeline Usage Examples

This document provides comprehensive examples for running the metagenomic analysis pipeline in various scenarios.

## Table of Contents

1. [Basic Examples](#basic-examples)
2. [Assembly Strategies](#assembly-strategies)
3. [Selective Analysis](#selective-analysis)
4. [Resource Optimization](#resource-optimization)
5. [Platform-Specific Examples](#platform-specific-examples)
6. [Advanced Workflows](#advanced-workflows)
7. [Troubleshooting Examples](#troubleshooting-examples)

## Basic Examples

### 1. Complete Pipeline with Docker

Run the full pipeline with all steps enabled:

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results_complete \
    --host_genome ~/databases/human_genome/human_GRCh38 \
    --metaphlan_db ~/databases/metaphlan_db \
    --humann_nucleotide_db ~/databases/humann_dbs/chocophlan \
    --humann_protein_db ~/databases/humann_dbs/uniref \
    --checkm_db ~/databases/checkm_data \
    --kegg_db ~/databases/kegg_db/kegg_db.dmnd \
    --cazy_db ~/databases/cazy_db/cazy_db.dmnd \
    -profile docker \
    -resume
```

### 2. Using the Quick Start Script

```bash
./scripts/run_pipeline.sh \
    -i samplesheet.csv \
    -o results \
    -d ~/databases \
    -p docker
```

### 3. Minimal Run (Taxonomy and Function Only)

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results_minimal \
    --metaphlan_db ~/databases/metaphlan_db \
    --humann_nucleotide_db ~/databases/humann_dbs/chocophlan \
    --humann_protein_db ~/databases/humann_dbs/uniref \
    --skip_assembly \
    --skip_binning \
    --skip_growth_rates \
    -profile docker
```

## Assembly Strategies

### 1. Individual Assembly (Default)

Each sample is assembled separately:

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results_individual \
    --assembler megahit \
    --min_contig_length 1000 \
    -profile docker
```

### 2. Co-assembly

All samples assembled together:

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results_coassembly \
    --coassembly \
    --assembler megahit \
    --min_contig_length 1000 \
    -profile docker
```

### 3. SPAdes Assembly

Use SPAdes instead of MEGAHIT (higher quality, slower):

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results_spades \
    --assembler spades \
    --min_contig_length 2000 \
    -profile docker
```

### 4. High-Quality Contig Filtering

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results_hq_contigs \
    --min_contig_length 5000 \
    --assembler megahit \
    -profile docker
```

## Selective Analysis

### 1. Only Quality Control and Preprocessing

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results_qc_only \
    --host_genome ~/databases/human_genome/human_GRCh38 \
    --skip_taxonomic \
    --skip_functional \
    --skip_assembly \
    --skip_binning \
    --skip_growth_rates \
    -profile docker
```

### 2. Skip Host Removal

If samples don't contain host DNA:

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results_no_host_removal \
    --skip_kneaddata \
    --metaphlan_db ~/databases/metaphlan_db \
    -profile docker
```

### 3. Assembly and Binning Only

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results_assembly_binning \
    --checkm_db ~/databases/checkm_data \
    --skip_qc \
    --skip_kneaddata \
    --skip_taxonomic \
    --skip_functional \
    -profile docker
```

### 4. Growth Rates from Existing Bins

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results_growth \
    --skip_qc \
    --skip_kneaddata \
    --skip_taxonomic \
    --skip_functional \
    --skip_assembly \
    -profile docker
```

## Resource Optimization

### 1. Low-Resource System (8 CPU, 32 GB RAM)

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results_lowres \
    --metaphlan_db ~/databases/metaphlan_db \
    --max_cpus 8 \
    --max_memory 32.GB \
    --max_time 120.h \
    --skip_assembly \
    --skip_binning \
    -profile docker
```

### 2. High-Performance System (64 CPU, 512 GB RAM)

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results_highperf \
    --host_genome ~/databases/human_genome/human_GRCh38 \
    --metaphlan_db ~/databases/metaphlan_db \
    --humann_nucleotide_db ~/databases/humann_dbs/chocophlan \
    --humann_protein_db ~/databases/humann_dbs/uniref \
    --checkm_db ~/databases/checkm_data \
    --max_cpus 64 \
    --max_memory 512.GB \
    --max_time 480.h \
    --coassembly \
    -profile docker
```

### 3. Memory-Efficient Configuration

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results_memeff \
    --assembler megahit \
    --max_memory 64.GB \
    --skip_coassembly \
    -profile docker
```

## Platform-Specific Examples

### 1. SLURM HPC Cluster

```bash
#!/bin/bash
#SBATCH --job-name=metagenomics
#SBATCH --time=72:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=metagenomics_%j.log

module load singularity

nextflow run main.nf \
    --input /scratch/$USER/samples.csv \
    --outdir /scratch/$USER/results \
    --host_genome /data/databases/human_genome/human_GRCh38 \
    --metaphlan_db /data/databases/metaphlan_db \
    --humann_nucleotide_db /data/databases/humann_dbs/chocophlan \
    --humann_protein_db /data/databases/humann_dbs/uniref \
    --checkm_db /data/databases/checkm_data \
    --max_cpus 32 \
    --max_memory 256.GB \
    -profile slurm \
    -work-dir /scratch/$USER/work \
    -resume
```

### 2. AWS Batch

```bash
# First, upload data to S3
aws s3 sync ./data s3://my-bucket/metagenomics/data/
aws s3 cp samplesheet.csv s3://my-bucket/metagenomics/

# Run pipeline
nextflow run main.nf \
    --input s3://my-bucket/metagenomics/samplesheet.csv \
    --outdir s3://my-bucket/metagenomics/results \
    --host_genome s3://my-bucket/databases/human_genome/human_GRCh38 \
    --metaphlan_db s3://my-bucket/databases/metaphlan_db \
    --humann_nucleotide_db s3://my-bucket/databases/humann_dbs/chocophlan \
    --humann_protein_db s3://my-bucket/databases/humann_dbs/uniref \
    --checkm_db s3://my-bucket/databases/checkm_data \
    -profile awsbatch \
    -work-dir s3://my-bucket/metagenomics/work \
    -resume
```

### 3. Google Cloud Platform

```bash
# Using Google Life Sciences API
nextflow run main.nf \
    --input gs://my-bucket/samplesheet.csv \
    --outdir gs://my-bucket/results \
    --metaphlan_db gs://my-bucket/databases/metaphlan_db \
    --humann_nucleotide_db gs://my-bucket/databases/humann_dbs/chocophlan \
    --humann_protein_db gs://my-bucket/databases/humann_dbs/uniref \
    -profile google \
    -work-dir gs://my-bucket/work
```

### 4. Local Workstation with Singularity

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results \
    --host_genome ~/databases/human_genome/human_GRCh38 \
    --metaphlan_db ~/databases/metaphlan_db \
    --humann_nucleotide_db ~/databases/humann_dbs/chocophlan \
    --humann_protein_db ~/databases/humann_dbs/uniref \
    --max_cpus 16 \
    --max_memory 128.GB \
    -profile singularity \
    -resume
```

## Advanced Workflows

### 1. Multiple Binning Tools

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results_multibinning \
    --binning_tools metabat2,maxbin2,concoct \
    --min_bin_completeness 70 \
    --max_bin_contamination 5 \
    --checkm_db ~/databases/checkm_data \
    -profile docker
```

### 2. High-Quality MAG Recovery

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results_hq_mags \
    --assembler spades \
    --min_contig_length 2500 \
    --binning_tools metabat2,maxbin2,concoct \
    --min_bin_completeness 90 \
    --max_bin_contamination 5 \
    --checkm_db ~/databases/checkm_data \
    --max_memory 256.GB \
    -profile docker
```

### 3. Comparative Metagenomics Study

```bash
# Process multiple cohorts separately
for cohort in healthy disease control; do
    nextflow run main.nf \
        --input ${cohort}_samples.csv \
        --outdir results_${cohort} \
        --host_genome ~/databases/human_genome/human_GRCh38 \
        --metaphlan_db ~/databases/metaphlan_db \
        --humann_nucleotide_db ~/databases/humann_dbs/chocophlan \
        --humann_protein_db ~/databases/humann_dbs/uniref \
        --checkm_db ~/databases/checkm_data \
        --kegg_db ~/databases/kegg_db/kegg_db.dmnd \
        -profile docker \
        -resume
done
```

### 4. Time-Series Analysis

```bash
# Process time-series samples with growth rate calculation
nextflow run main.nf \
    --input timeseries_samples.csv \
    --outdir results_timeseries \
    --host_genome ~/databases/human_genome/human_GRCh38 \
    --coassembly \
    --binning_tools metabat2,maxbin2 \
    --checkm_db ~/databases/checkm_data \
    --skip_functional \
    -profile docker
```

### 5. Strain-Level Analysis

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results_strain \
    --metaphlan_db ~/databases/metaphlan_db \
    --assembler spades \
    --min_contig_length 5000 \
    --binning_tools metabat2,maxbin2,concoct \
    --min_bin_completeness 95 \
    --max_bin_contamination 2 \
    -profile docker
```

## Troubleshooting Examples

### 1. Resume After Failure

```bash
# Pipeline failed? Just add -resume
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results \
    --metaphlan_db ~/databases/metaphlan_db \
    -profile docker \
    -resume
```

### 2. Test Run with Small Dataset

```bash
# Use test profile with small dataset
nextflow run main.nf \
    --input test/test_samplesheet.csv \
    --outdir test_results \
    --metaphlan_db ~/databases/metaphlan_db \
    --max_cpus 4 \
    --max_memory 16.GB \
    -profile test,docker
```

### 3. Debug Mode

```bash
# Enable debug output
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results_debug \
    --metaphlan_db ~/databases/metaphlan_db \
    -profile docker \
    -with-trace \
    -with-report \
    -with-timeline \
    -with-dag flowchart.html
```

### 4. Specific Process Retry

```bash
# If specific processes fail due to memory
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results \
    --metaphlan_db ~/databases/metaphlan_db \
    --max_memory 256.GB \
    -profile docker \
    -resume
```

### 5. Clean and Restart

```bash
# Clean all cached results and start fresh
rm -rf work .nextflow*
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results_clean \
    --metaphlan_db ~/databases/metaphlan_db \
    -profile docker
```

## Batch Processing Examples

### 1. Process Multiple Projects

```bash
#!/bin/bash
# process_all_projects.sh

PROJECTS=("project1" "project2" "project3")

for project in "${PROJECTS[@]}"; do
    echo "Processing $project..."
    nextflow run main.nf \
        --input ${project}_samples.csv \
        --outdir results_${project} \
        --host_genome ~/databases/human_genome/human_GRCh38 \
        --metaphlan_db ~/databases/metaphlan_db \
        --humann_nucleotide_db ~/databases/humann_dbs/chocophlan \
        --humann_protein_db ~/databases/humann_dbs/uniref \
        -profile docker \
        -resume
done
```

### 2. Parallel Project Processing

```bash
#!/bin/bash
# parallel_processing.sh

# Process multiple projects in parallel using different work directories
parallel -j 3 "nextflow run main.nf \
    --input {}_samples.csv \
    --outdir results_{} \
    --metaphlan_db ~/databases/metaphlan_db \
    -profile docker \
    -work-dir work_{} \
    -resume" ::: project1 project2 project3
```

## Real-World Scenarios

### 1. Human Gut Microbiome Study

```bash
nextflow run main.nf \
    --input gut_samples.csv \
    --outdir results_gut_microbiome \
    --host_genome ~/databases/human_genome/human_GRCh38 \
    --metaphlan_db ~/databases/metaphlan_db \
    --humann_nucleotide_db ~/databases/humann_dbs/chocophlan \
    --humann_protein_db ~/databases/humann_dbs/uniref \
    --checkm_db ~/databases/checkm_data \
    --kegg_db ~/databases/kegg_db/kegg_db.dmnd \
    --cazy_db ~/databases/cazy_db/cazy_db.dmnd \
    --binning_tools metabat2,maxbin2 \
    --min_bin_completeness 50 \
    --max_bin_contamination 10 \
    -profile docker \
    -resume
```

### 2. Soil Metagenomics

```bash
# No host removal needed for soil
nextflow run main.nf \
    --input soil_samples.csv \
    --outdir results_soil \
    --skip_kneaddata \
    --metaphlan_db ~/databases/metaphlan_db \
    --humann_nucleotide_db ~/databases/humann_dbs/chocophlan \
    --humann_protein_db ~/databases/humann_dbs/uniref \
    --coassembly \
    --assembler megahit \
    --binning_tools metabat2,maxbin2,concoct \
    --checkm_db ~/databases/checkm_data \
    -profile docker
```

### 3. Marine Microbiome

```bash
nextflow run main.nf \
    --input ocean_samples.csv \
    --outdir results_marine \
    --skip_kneaddata \
    --metaphlan_db ~/databases/metaphlan_db \
    --coassembly \
    --assembler megahit \
    --min_contig_length 1000 \
    --binning_tools metabat2,maxbin2 \
    --checkm_db ~/databases/checkm_data \
    --max_cpus 32 \
    --max_memory 256.GB \
    -profile docker
```

### 4. Clinical Samples (High-Throughput)

```bash
# Process 100+ clinical samples
nextflow run main.nf \
    --input clinical_samples.csv \
    --outdir results_clinical \
    --host_genome ~/databases/human_genome/human_GRCh38 \
    --metaphlan_db ~/databases/metaphlan_db \
    --humann_nucleotide_db ~/databases/humann_dbs/chocophlan \
    --humann_protein_db ~/databases/humann_dbs/uniref \
    --skip_assembly \
    --skip_binning \
    --skip_growth_rates \
    --max_cpus 64 \
    -profile slurm \
    -resume
```

### 5. Antibiotic Resistance Profiling

```bash
nextflow run main.nf \
    --input samples.csv \
    --outdir results_amr \
    --host_genome ~/databases/human_genome/human_GRCh38 \
    --metaphlan_db ~/databases/metaphlan_db \
    --assembler megahit \
    --kegg_db ~/databases/kegg_db/kegg_db.dmnd \
    --ardb_db ~/databases/ardb/ardb.dmnd \
    --skip_binning \
    --skip_growth_rates \
    -profile docker
```

## Performance Optimization Examples

### 1. Maximize Throughput

```bash
# Use all available resources
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results_max_throughput \
    --metaphlan_db ~/databases/metaphlan_db \
    --humann_nucleotide_db ~/databases/humann_dbs/chocophlan \
    --humann_protein_db ~/databases/humann_dbs/uniref \
    --max_cpus 64 \
    --max_memory 512.GB \
    -profile docker
```

### 2. Minimize Disk Usage

```bash
# Clean work directory automatically
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results \
    --metaphlan_db ~/databases/metaphlan_db \
    -profile docker \
    -with-cleanup
```

### 3. Network-Optimized (Cloud)

```bash
# Optimize for cloud storage access
nextflow run main.nf \
    --input s3://bucket/samples.csv \
    --outdir s3://bucket/results \
    --metaphlan_db s3://bucket/databases/metaphlan_db \
    -profile awsbatch \
    -work-dir s3://bucket/work
```

## Generating Samplesheets

### 1. From Directory

```bash
# Auto-generate samplesheet from fastq directory
python scripts/generate_samplesheet.py \
    --directory /path/to/fastq_files \
    --output samplesheet.csv \
    --pattern "*_R{1,2}.fastq.gz"
```

### 2. Manual Creation

```bash
# Create samplesheet manually
cat > samplesheet.csv << EOF
sample,fastq_1,fastq_2
sample1,/data/sample1_R1.fastq.gz,/data/sample1_R2.fastq.gz
sample2,/data/sample2_R1.fastq.gz,/data/sample2_R2.fastq.gz
sample3,/data/sample3_R1.fastq.gz,/data/sample3_R2.fastq.gz
EOF
```

## Summary

These examples cover most common use cases. For custom workflows:

1. Start with a basic example
2. Add/remove optional steps using `--skip_*` flags
3. Adjust resources with `--max_cpus`, `--max_memory`, `--max_time`
4. Choose appropriate profile: `docker`, `singularity`, `conda`, `slurm`, `awsbatch`
5. Always use `-resume` to continue interrupted runs

For more help:
- Check `README.md` for parameter descriptions
- See `SETUP.md` for installation instructions
- Review `docs/troubleshooting.md` for common issues
