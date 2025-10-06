#!/bin/bash

################################################################################
# Metagenomic Pipeline Quick Start Script
################################################################################
# This script provides an easy way to run the metagenomic pipeline with
# commonly used configurations
################################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "${GREEN}[$(date +%Y-%m-%d\ %H:%M:%S)]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Metagenomic Pipeline Quick Start Script

Required Options:
    -i, --input FILE          Input samplesheet CSV file
    -o, --outdir DIR          Output directory for results
    -d, --databases DIR       Directory containing all databases

Optional Database Paths (override defaults):
    --host-genome PATH        Path to host genome index
    --metaphlan-db PATH       Path to MetaPhlAn database
    --humann-nucl PATH        Path to HUMAnN nucleotide database
    --humann-prot PATH        Path to HUMAnN protein database
    --checkm-db PATH          Path to CheckM database
    --kegg-db PATH            Path to KEGG database
    --cazy-db PATH            Path to CAZy database

Pipeline Control:
    --skip-qc                 Skip quality control
    --skip-kneaddata          Skip KneadData preprocessing
    --skip-assembly           Skip assembly
    --skip-binning            Skip genome binning
    --skip-growth             Skip growth rate calculation
    --skip-functional         Skip functional annotation
    --skip-taxonomic          Skip taxonomic profiling
    --coassembly              Perform co-assembly instead of individual

Assembly Options:
    --assembler TYPE          Assembler: megahit or spades (default: megahit)
    --min-contig INT          Minimum contig length (default: 1000)

Binning Options:
    --binning-tools STR       Binning tools (default: metabat2,maxbin2)
    --min-completeness INT    Minimum bin completeness (default: 50)
    --max-contamination INT   Maximum bin contamination (default: 10)

Resource Options:
    --cpus INT                Maximum CPUs per process (default: 16)
    --memory STR              Maximum memory per process (default: 128.GB)
    --time STR                Maximum time per process (default: 240.h)

Execution Options:
    -p, --profile STR         Execution profile: docker, singularity, conda, slurm, awsbatch
    -r, --resume              Resume previous run
    -w, --work-dir DIR        Work directory (default: ./work)

Other Options:
    -h, --help                Display this help message
    --dry-run                 Show commands without executing

Examples:
    # Basic run with Docker
    $0 -i samples.csv -o results -d /path/to/databases -p docker

    # HPC run with SLURM
    $0 -i samples.csv -o results -d /path/to/databases -p slurm --cpus 32 --memory 256.GB

    # Skip assembly and binning, only taxonomic/functional
    $0 -i samples.csv -o results -d /path/to/databases -p docker \\
       --skip-assembly --skip-binning --skip-growth

    # Co-assembly mode
    $0 -i samples.csv -o results -d /path/to/databases -p docker --coassembly

    # Resume previous run
    $0 -i samples.csv -o results -d /path/to/databases -p docker -r

EOF
    exit 1
}

# Default values
INPUT=""
OUTDIR=""
DATABASE_DIR=""
PROFILE="docker"
RESUME=""
WORK_DIR="./work"
DRY_RUN=false

# Database paths
HOST_GENOME=""
METAPHLAN_DB=""
HUMANN_NUCL=""
HUMANN_PROT=""
CHECKM_DB=""
KEGG_DB=""
CAZY_DB=""

# Pipeline control flags
SKIP_FLAGS=""
COASSEMBLY=""

# Assembly options
ASSEMBLER="megahit"
MIN_CONTIG="1000"

# Binning options
BINNING_TOOLS="metabat2,maxbin2"
MIN_COMPLETENESS="50"
MAX_CONTAMINATION="10"

# Resource options
MAX_CPUS="16"
MAX_MEMORY="128.GB"
MAX_TIME="240.h"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input)
            INPUT="$2"
            shift 2
            ;;
        -o|--outdir)
            OUTDIR="$2"
            shift 2
            ;;
        -d|--databases)
            DATABASE_DIR="$2"
            shift 2
            ;;
        --host-genome)
            HOST_GENOME="$2"
            shift 2
            ;;
        --metaphlan-db)
            METAPHLAN_DB="$2"
            shift 2
            ;;
        --humann-nucl)
            HUMANN_NUCL="$2"
            shift 2
            ;;
        --humann-prot)
            HUMANN_PROT="$2"
            shift 2
            ;;
        --checkm-db)
            CHECKM_DB="$2"
            shift 2
            ;;
        --kegg-db)
            KEGG_DB="$2"
            shift 2
            ;;
        --cazy-db)
            CAZY_DB="$2"
            shift 2
            ;;
        --skip-qc)
            SKIP_FLAGS="$SKIP_FLAGS --skip_qc"
            shift
            ;;
        --skip-kneaddata)
            SKIP_FLAGS="$SKIP_FLAGS --skip_kneaddata"
            shift
            ;;
        --skip-assembly)
            SKIP_FLAGS="$SKIP_FLAGS --skip_assembly"
            shift
            ;;
        --skip-binning)
            SKIP_FLAGS="$SKIP_FLAGS --skip_binning"
            shift
            ;;
        --skip-growth)
            SKIP_FLAGS="$SKIP_FLAGS --skip_growth_rates"
            shift
            ;;
        --skip-functional)
            SKIP_FLAGS="$SKIP_FLAGS --skip_functional"
            shift
            ;;
        --skip-taxonomic)
            SKIP_FLAGS="$SKIP_FLAGS --skip_taxonomic"
            shift
            ;;
        --coassembly)
            COASSEMBLY="--coassembly"
            shift
            ;;
        --assembler)
            ASSEMBLER="$2"
            shift 2
            ;;
        --min-contig)
            MIN_CONTIG="$2"
            shift 2
            ;;
        --binning-tools)
            BINNING_TOOLS="$2"
            shift 2
            ;;
        --min-completeness)
            MIN_COMPLETENESS="$2"
            shift 2
            ;;
        --max-contamination)
            MAX_CONTAMINATION="$2"
            shift 2
            ;;
        --cpus)
            MAX_CPUS="$2"
            shift 2
            ;;
        --memory)
            MAX_MEMORY="$2"
            shift 2
            ;;
        --time)
            MAX_TIME="$2"
            shift 2
            ;;
        -p|--profile)
            PROFILE="$2"
            shift 2
            ;;
        -r|--resume)
            RESUME="-resume"
            shift
            ;;
        -w|--work-dir)
            WORK_DIR="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Check required arguments
if [ -z "$INPUT" ]; then
    print_error "Input samplesheet is required (-i/--input)"
    usage
fi

if [ -
