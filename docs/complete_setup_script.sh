#!/bin/bash

################################################################################
# Complete Repository Setup Script
# This script automates the entire repository setup process
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Main setup
print_header "Metagenomic Pipeline Repository Setup"
echo ""

# Get download directory
read -p "Enter path to downloaded .groovy/.txt files (default: ~/Downloads): " DOWNLOAD_DIR
DOWNLOAD_DIR=${DOWNLOAD_DIR:-~/Downloads}

if [ ! -d "$DOWNLOAD_DIR" ]; then
    print_error "Download directory not found: $DOWNLOAD_DIR"
    exit 1
fi

# Get target directory
read -p "Enter repository name (default: metagenomics-nf-pipeline): " REPO_NAME
REPO_NAME=${REPO_NAME:-metagenomics-nf-pipeline}

# Create repository directory
if [ -d "$REPO_NAME" ]; then
    print_warning "Directory $REPO_NAME already exists"
    read -p "Do you want to overwrite? (yes/no): " OVERWRITE
    if [ "$OVERWRITE" != "yes" ]; then
        print_error "Setup cancelled"
        exit 1
    fi
    rm -rf "$REPO_NAME"
fi

mkdir -p "$REPO_NAME"
cd "$REPO_NAME"

print_success "Created repository directory: $REPO_NAME"

# Create directory structure
print_header "Creating Directory Structure"

mkdir -p conf
mkdir -p modules/{qc,preprocessing,taxonomy,functional,assembly,annotation,mapping,binning,clustering,growth}
mkdir -p bin
mkdir -p scripts
mkdir -p assets
mkdir -p docs
mkdir -p test/data
mkdir -p workflows
mkdir -p examples
mkdir -p .github/{workflows,ISSUE_TEMPLATE}

print_success "Directory structure created"

# Copy and rename main files
print_header "Organizing Main Files"

# Main workflow and config
if [ -f "$DOWNLOAD_DIR/metagenome_pipeline.groovy" ]; then
    cp "$DOWNLOAD_DIR/metagenome_pipeline.groovy" main.nf
    print_success "main.nf"
fi

if [ -f "$DOWNLOAD_DIR/nextflow_config.groovy" ]; then
    cp "$DOWNLOAD_DIR/nextflow_config.groovy" nextflow.config
    print_success "nextflow.config"
fi

# Configuration files
print_header "Copying Configuration Files"

[ -f "$DOWNLOAD_DIR/base_config.groovy" ] && cp "$DOWNLOAD_DIR/base_config.groovy" conf/base.config && print_success "conf/base.config"
[ -f "$DOWNLOAD_DIR/slurm_config.groovy" ] && cp "$DOWNLOAD_DIR/slurm_config.groovy" conf/slurm.config && print_success "conf/slurm.config"
[ -f "$DOWNLOAD_DIR/aws_config.groovy" ] && cp "$DOWNLOAD_DIR/aws_config.groovy" conf/awsbatch.config && print_success "conf/awsbatch.config"
[ -f "$DOWNLOAD_DIR/docker_singularity_config.groovy" ] && cp "$DOWNLOAD_DIR/docker_singularity_config.groovy" conf/docker.config && print_success "conf/docker.config"

# Create additional config files
cat > conf/singularity.config << 'EOF'
singularity {
    enabled = true
    autoMounts = true
    cacheDir = "$HOME/.singularity_cache"
}
EOF
print_success "conf/singularity.config"

cat > conf/conda.config << 'EOF'
conda {
    enabled = true
    cacheDir = "$HOME/.conda_cache"
}
EOF
print_success "conf/conda.config"

cat > conf/test.config << 'EOF'
params {
    input = 'test/test_samplesheet.csv'
    outdir = 'test_results'
    max_cpus = 2
    max_memory = 6.GB
    max_time = 2.h
}
EOF
print_success "conf/test.config"

# Module files
print_header "Copying Module Files"

[ -f "$DOWNLOAD_DIR/kneaddata_module.groovy" ] && cp "$DOWNLOAD_DIR/kneaddata_module.groovy" modules/preprocessing/kneaddata.nf && print_success "kneaddata.nf"
[ -f "$DOWNLOAD_DIR/metaphlan_module.groovy" ] && cp "$DOWNLOAD_DIR/metaphlan_module.groovy" modules/taxonomy/metaphlan.nf && print_success "metaphlan.nf"
[ -f "$DOWNLOAD_DIR/humann_module.groovy" ] && cp "$DOWNLOAD_DIR/humann_module.groovy" modules/functional/humann.nf && print_success "humann.nf"
[ -f "$DOWNLOAD_DIR/megahit_module.groovy" ] && cp "$DOWNLOAD_DIR/megahit_module.groovy" modules/assembly/megahit.nf && print_success "megahit.nf"

# Documentation files
print_header "Copying Documentation"

[ -f "$DOWNLOAD_DIR/readme_file.txt" ] && cp "$DOWNLOAD_DIR/readme_file.txt" README.md && print_success "README.md"
[ -f "$DOWNLOAD_DIR/setup_guide.txt" ] && cp "$DOWNLOAD_DIR/setup_guide.txt" SETUP.md && print_success "SETUP.md"
[ -f "$DOWNLOAD_DIR/getting_started.txt" ] && cp "$DOWNLOAD_DIR/getting_started.txt" GETTING_STARTED.md && print_success "GETTING_STARTED.md"
[ -f "$DOWNLOAD_DIR/usage_examples.txt" ] && cp "$DOWNLOAD_DIR/usage_examples.txt" EXAMPLES.md && print_success "EXAMPLES.md"
[ -f "$DOWNLOAD_DIR/project_structure.txt" ] && cp "$DOWNLOAD_DIR/project_structure.txt" PROJECT_STRUCTURE.md && print_success "PROJECT_STRUCTURE.md"

# Scripts
print_header "Copying Scripts"

[ -f "$DOWNLOAD_DIR/quick_start_script.sh" ] && cp "$DOWNLOAD_DIR/quick_start_script.sh" scripts/run_pipeline.sh && chmod +x scripts/run_pipeline.sh && print_success "scripts/run_pipeline.sh"

# Example files
[ -f "$DOWNLOAD_DIR/example_samplesheet.csv" ] && cp "$DOWNLOAD_DIR/example_samplesheet.csv" examples/samplesheet.csv && print_success "examples/samplesheet.csv"

# Create .gitignore
print_header "Creating Essential Files"

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
dag.dot

# Results
results/
test_results/

# Databases
databases/
*.dmnd
*.bt2
*.bam
*.sam

# Python
__pycache__/
*.py[cod]

# R
.Rhistory
.RData

# System
.DS_Store
Thumbs.db

# Containers
*.sif
EOF
print_success ".gitignore"

# Create LICENSE
cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2024 Ashok K. Sharma

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
print_success "LICENSE"

# Create CHANGELOG.md
cat > CHANGELOG.md << 'EOF'
# Changelog

## [1.0.0] - 2024-10-06

### Added
- Initial release of comprehensive metagenomic analysis pipeline
- Complete workflow from raw reads to functional annotations and growth rates
- Support for Docker, Singularity, and Conda
- Support for SLURM HPC and AWS Batch execution
- Comprehensive documentation and examples

### Features
- Quality control with FastQC and MultiQC
- Read preprocessing with KneadData
- Taxonomic profiling with MetaPhlAn4
- Functional profiling with HUMAnN3
- Metagenomic assembly with MEGAHIT and SPAdes
- Genome binning with MetaBAT2, MaxBin2, and CONCOCT
- Bin quality assessment with CheckM
- Bacterial growth rate calculation with DEMIC
- Functional annotation with KEGG and CAZy
- Modular design with flexible configuration
EOF
print_success "CHANGELOG.md"

# Make all files executable
print_header "Setting Permissions"

chmod +x scripts/*.sh 2>/dev/null || true
chmod +x bin/*.py 2>/dev/null || true
chmod +x bin/*.R 2>/dev/null || true

print_success "Permissions set"

# Summary
print_header "Setup Complete!"
echo ""
echo -e "${GREEN}Repository created successfully at: $(pwd)${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review and manually split combined module files:"
echo "   - binning_modules.groovy"
echo "   - annotation_modules.groovy"
echo "   - mapping_modules.groovy"
echo "   - growth_cdhit_modules.groovy"
echo ""
echo "2. Initialize git repository:"
echo "   git init"
echo "   git add ."
echo "   git commit -m 'Initial commit'"
echo ""
echo "3. Create GitHub repository and push:"
echo "   git remote add origin https://github.com/yourusername/metagenomics-nf-pipeline.git"
echo "   git push -u origin main"
echo ""
echo "4. Test the pipeline:"
echo "   nextflow run main.nf --help"
echo ""
echo -e "${BLUE}For detailed instructions, see GETTING_STARTED.md${NC}"
