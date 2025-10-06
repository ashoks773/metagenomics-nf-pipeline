cat > examples/run_aws.sh << 'EOF'
#!/bin/bash

# Example: Run on AWS Batch

nextflow run main.nf \
    --input s3://my-bucket/samplesheet.csv \
    --outdir s3://my-bucket/results \
    --metaphlan_db s3://my-bucket/databases/metaphlan_db \
    --humann_nucleotide_db s3://my-bucket/databases/humann_dbs/chocophlan \
    --humann_protein_db s3://my-bucket/databases/humann_dbs/uniref \
    -profile awsbatch \
    -work-dir s3://my-bucket/work
EOF

chmod +x examples/run_aws.sh
