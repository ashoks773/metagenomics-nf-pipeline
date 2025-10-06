# Setup Guide for Metagenomic Pipeline

This guide will help you set up all required databases and dependencies for the metagenomic analysis pipeline.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Install Nextflow](#install-nextflow)
3. [Container System Setup](#container-system-setup)
4. [Database Setup](#database-setup)
5. [Testing the Pipeline](#testing-the-pipeline)
6. [AWS Setup (Optional)](#aws-setup-optional)

## System Requirements

### Minimum Requirements
- **CPU**: 16 cores
- **RAM**: 64 GB
- **Storage**: 500 GB (for databases and intermediate files)
- **OS**: Linux (Ubuntu 20.04+, CentOS 7+, or similar)

### Recommended Requirements
- **CPU**: 32+ cores
- **RAM**: 128+ GB
- **Storage**: 1 TB SSD
- **OS**: Linux with SLURM job scheduler

## Install Nextflow

### Prerequisites
Install Java 11 or later:

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y default-jdk

# CentOS/RHEL
sudo yum install -y java-11-openjdk
```

### Install Nextflow

```bash
# Download and install Nextflow
curl -s https://get.nextflow.io | bash

# Move to system path
sudo mv nextflow /usr/local/bin/

# Verify installation
nextflow -version
```

## Container System Setup

You need one of the following container systems:

### Option 1: Docker (Recommended for local/cloud)

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
```

### Option 2: Singularity (Recommended for HPC)

```bash
# Install dependencies (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    libssl-dev \
    uuid-dev \
    libgpgme11-dev \
    squashfs-tools \
    libseccomp-dev \
    wget \
    pkg-config \
    git \
    cryptsetup

# Install Go
export VERSION=1.20.5 OS=linux ARCH=amd64
wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz
sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz
rm go$VERSION.$OS-$ARCH.tar.gz

echo 'export PATH=/usr/local/go/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Install Singularity
export VERSION=3.11.4
wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-ce-${VERSION}.tar.gz
tar -xzf singularity-ce-${VERSION}.tar.gz
cd singularity-ce-${VERSION}

./mconfig
make -C builddir
sudo make -C builddir install

# Verify installation
singularity --version
```

### Option 3: Conda (Alternative, slower)

```bash
# Install Miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

# Follow prompts and initialize conda
source ~/.bashrc

# Verify installation
conda --version
```

## Database Setup

Create a directory for all databases:

```bash
mkdir -p ~/metagenomics_databases
cd ~/metagenomics_databases
```

### 1. Host Genome (Human GRCh38)

```bash
# Create directory
mkdir -p human_genome
cd human_genome

# Download human genome
wget http://ftp.ensembl.org/pub/release-109/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz

# Decompress
gunzip Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz

# Build Bowtie2 index
bowtie2-build Homo_sapiens.GRCh38.dna.primary_assembly.fa human_GRCh38

cd ..
```

**Alternative: Use KneadData to download**

```bash
kneaddata_database --download human_genome bowtie2 human_genome/
```

### 2. MetaPhlAn Database

```bash
mkdir -p metaphlan_db
cd metaphlan_db

# Download MetaPhlAn database (this may take a while)
metaphlan --install --bowtie2db .

cd ..
```

### 3. HUMAnN Databases

```bash
# ChocoPhlAn (pangenome database)
mkdir -p humann_dbs
humann_databases --download chocophlan full humann_dbs --update-config yes

# UniRef90 (protein database)
humann_databases --download uniref uniref90_diamond humann_dbs --update-config yes

# Utility mapping databases (optional but recommended)
humann_databases --download utility_mapping full humann_dbs --update-config yes
```

**Note**: These downloads are very large (>40 GB total) and may take several hours.

### 4. CheckM Database

```bash
mkdir -p checkm_data
cd checkm_data

# Download CheckM database
wget https://data.ace.uq.edu.au/public/CheckM_databases/checkm_data_2015_01_16.tar.gz

# Extract
tar -xzf checkm_data_2015_01_16.tar.gz

# Set CheckM data location
checkm data setRoot $(pwd)

cd ..
```

### 5. KEGG Database (Optional)

The KEGG database requires a subscription. If you have access:

```bash
mkdir -p kegg_db
cd kegg_db

# Download KEGG genes database from your institution
# Example: using KEGG API or institution mirror
# Build DIAMOND database
diamond makedb --in kegg_genes.fasta -d kegg_db

cd ..
```

**Alternative**: Use a pre-built KEGG database from your institution or use the free eggNOG database:

```bash
mkdir -p eggnog_db
cd eggnog_db

# Download eggNOG database
download_eggnog_data.py -y

cd ..
```

### 6. CAZy Database (Optional)

```bash
mkdir -p cazy_db
cd cazy_db

# Download CAZy database
# Visit http://www.cazy.org/ for access
# Or use dbCAN database (open alternative)
wget http://bcb.unl.edu/dbCAN2/download/CAZyDB.07262020.fa

# Build DIAMOND database
diamond makedb --in CAZyDB.07262020.fa -d cazy_db

cd ..
```

### 7. ARDB (Antibiotic Resistance Database) (Optional)

```bash
mkdir -p ardb
cd ardb

# Download ARDB
wget https://ardb.cbcb.umd.edu/download/ardb_download.tar.gz
tar -xzf ardb_download.tar.gz

# Build DIAMOND database
diamond makedb --in ardbAnno1.0.fa -d ardb

cd ..
```

## Database Size Summary

| Database | Size | Download Time (100 Mbps) |
|----------|------|-------------------------|
| Human Genome | ~3 GB | ~5 minutes |
| MetaPhlAn | ~5 GB | ~7 minutes |
| HUMAnN ChocoPhlAn | ~20 GB | ~30 minutes |
| HUMAnN UniRef90 | ~20 GB | ~30 minutes |
| CheckM | ~275 MB | ~1 minute |
| KEGG | ~10 GB | ~15 minutes |
| CAZy | ~500 MB | ~1 minute |
| ARDB | ~50 MB | <1 minute |
| **Total** | **~60 GB** | **~90 minutes** |

## Testing the Pipeline

### 1. Create a test dataset

```bash
# Create test directory
mkdir -p test_run
cd test_run

# Create a minimal samplesheet
cat > test_samplesheet.csv << EOF
sample,fastq_1,fastq_2
test_sample,test_R1.fastq.gz,test_R2.fastq.gz
EOF

# Download a small test dataset (or use your own)
# Example: Download from SRA
fastq-dump --split-files --gzip SRR5936130

# Rename to match samplesheet
mv SRR5936130_1.fastq.gz test_R1.fastq.gz
mv SRR5936130_2.fastq.gz test_R2.fastq.gz
```

### 2. Run a minimal test

```bash
nextflow run /path/to/pipeline/main.nf \
    --input test_samplesheet.csv \
    --outdir test_results \
    --skip_assembly \
    --skip_binning \
    --skip_growth_rates \
    --skip_functional \
    --metaphlan_db ~/metagenomics_databases/metaphlan_db \
    -profile docker \
    -resume
```

### 3. Run full pipeline test

```bash
nextflow run /path/to/pipeline/main.nf \
    --input test_samplesheet.csv \
    --outdir test_results_full \
    --host_genome ~/metagenomics_databases/human_genome/human_GRCh38 \
    --metaphlan_db ~/metagenomics_databases/metaphlan_db \
    --humann_nucleotide_db ~/metagenomics_databases/humann_dbs/chocophlan \
    --humann_protein_db ~/metagenomics_databases/humann_dbs/uniref \
    --checkm_db ~/metagenomics_databases/checkm_data \
    --max_cpus 8 \
    --max_memory 32.GB \
    -profile docker \
    -resume
```

## AWS Setup (Optional)

### 1. Install AWS CLI

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS credentials
aws configure
```

### 2. Set up AWS Batch

```bash
# Create S3 bucket for data and work directory
aws s3 mb s3://your-metagenomics-bucket

# Upload databases to S3
aws s3 sync ~/metagenomics_databases s3://your-metagenomics-bucket/databases/

# Upload your data
aws s3 sync /path/to/your/data s3://your-metagenomics-bucket/raw_data/
```

### 3. Create AWS Batch compute environment

Follow AWS documentation or use the provided CloudFormation template:

```bash
# Deploy CloudFormation stack
aws cloudformation create-stack \
    --stack-name metagenomics-batch \
    --template-body file://aws_batch_setup.yaml \
    --capabilities CAPABILITY_IAM
```

### 4. Run pipeline on AWS

```bash
nextflow run /path/to/pipeline/main.nf \
    --input s3://your-metagenomics-bucket/samplesheet.csv \
    --outdir s3://your-metagenomics-bucket/results \
    --host_genome s3://your-metagenomics-bucket/databases/human_genome/human_GRCh38 \
    --metaphlan_db s3://your-metagenomics-bucket/databases/metaphlan_db \
    --humann_nucleotide_db s3://your-metagenomics-bucket/databases/humann_dbs/chocophlan \
    --humann_protein_db s3://your-metagenomics-bucket/databases/humann_dbs/uniref \
    -profile awsbatch \
    -work-dir s3://your-metagenomics-bucket/work
```

## Troubleshooting

### Issue: Out of memory errors

**Solution**: Increase memory allocation or use compute nodes with more RAM

```bash
nextflow run main.nf --max_memory 256.GB [other options]
```

### Issue: Database download fails

**Solution**: Use alternative mirrors or wget with resume capability

```bash
wget -c <database_url>  # -c resumes interrupted downloads
```

### Issue: Permission denied errors

**Solution**: Check file permissions and Docker/Singularity configuration

```bash
# For Docker
sudo usermod -aG docker $USER
newgrp docker

# For file permissions
chmod -R 755 /path/to/pipeline
```

### Issue: Nextflow can't find Java

**Solution**: Install Java and set JAVA_HOME

```bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH
```

## Support

For issues and questions:
- Check the [README.md](README.md) for usage instructions
- Open an issue on GitHub
- Email: ashoks773@gmail.com

## Updating the Pipeline

```bash
# Pull latest changes
cd /path/to/pipeline
git pull

# Clean old work directory
nextflow clean -f

# Run with updated code
nextflow run main.nf [options] -resume
```
