cat > examples/run_local.sh << 'EOF'
#!/bin/bash

# Example: Run locally with Docker

nextflow run ../main.nf \
    --input samplesheet.csv \
    --outdir results \
    --host_genome ~/databases/human_genome/human_GRCh38 \
    --metaphlan_db ~/databases/metaphlan_db \
    --humann_nucleotide_db ~/databases/humann_dbs/chocophlan \
    --humann_protein_db ~/databases/humann_dbs/uniref \
    -profile docker \
    -resume
EOF

chmod +x examples/run_local.sh
