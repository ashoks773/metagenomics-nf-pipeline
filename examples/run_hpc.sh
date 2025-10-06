cat > examples/run_hpc.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=metagenomics
#SBATCH --time=72:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=pipeline_%j.log

module load singularity nextflow

nextflow run /path/to/metagenomics-nf-pipeline/main.nf \
    --input samplesheet.csv \
    --outdir results \
    --host_genome /data/databases/human_genome/human_GRCh38 \
    --metaphlan_db /data/databases/metaphlan_db \
    --humann_nucleotide_db /data/databases/humann_dbs/chocophlan \
    --humann_protein_db /data/databases/humann_dbs/uniref \
    -profile slurm \
    -resume
EOF

chmod +x examples/run_hpc.sh
