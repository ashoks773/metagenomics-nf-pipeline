cat > scripts/setup_databases.sh << 'EOF'
#!/bin/bash

# Database setup script
# This script downloads all required databases

set -e

DB_DIR="${1:-$HOME/metagenomics_databases}"

echo "Setting up databases in: $DB_DIR"
mkdir -p "$DB_DIR"
cd "$DB_DIR"

# MetaPhlAn
echo "Downloading MetaPhlAn database..."
mkdir -p metaphlan_db
metaphlan --install --bowtie2db metaphlan_db

# HUMAnN
echo "Downloading HUMAnN databases..."
mkdir -p humann_dbs
humann_databases --download chocophlan full humann_dbs
humann_databases --download uniref uniref90_diamond humann_dbs

# CheckM
echo "Downloading CheckM database..."
mkdir -p checkm_data
cd checkm_data
wget https://data.ace.uq.edu.au/public/CheckM_databases/checkm_data_2015_01_16.tar.gz
tar -xzf checkm_data_2015_01_16.tar.gz
checkm data setRoot $(pwd)
cd ..

echo "Database setup complete!"
echo "Database location: $DB_DIR"
EOF

chmod +x scripts/setup_databases.sh
