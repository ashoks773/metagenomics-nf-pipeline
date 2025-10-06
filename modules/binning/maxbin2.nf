process MAXBIN2 {
    tag "$sample"
    label 'process_medium'
    publishDir "${params.outdir}/09_binning/maxbin2/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::maxbin2=2.2.7" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/maxbin2:2.2.7--h7d875b9_3' :
        'quay.io/biocontainers/maxbin2:2.2.7--h7d875b9_3' }"
    
    input:
    tuple val(sample), path(contigs), path(bams)
    
    output:
    tuple val(sample), path("bins/*.fasta"), emit: bins
    path("${sample}_maxbin2.log"), emit: log
    
    script:
    """
    # Calculate abundances using BBMap pileup
    mkdir -p abundance
    for bam in ${bams}; do
        base=\$(basename \$bam .bam)
        pileup.sh in=\$bam out=abundance/\${base}.cov.txt
:    
    input:
    tuple val(sample), path(contigs), path(bams)
    
    output:
    tuple val(sample), path("bins/*.fasta"), emit: bins
    path("${sample}_maxbin2.log"), emit: log
    
    script:
    """
    # Calculate abundances using BBMap pileup
    mkdir -p abundance
    for bam in ${bams}; do
        base=\$(basename \$bam .bam)
        pileup.sh in=\$bam out=abundance/\${base}.cov.txt
        awk '{print \$1"\\t"\$5}' abundance/\${base}.cov.txt | grep -v '^#' > abundance/\${base}.abundance.txt
:    
    input:
    tuple val(sample), path(contigs), path(bams)
    
    output:
    tuple val(sample), path("bins/*.fasta"), emit: bins
    path("${sample}_maxbin2.log"), emit: log
    
    script:
    """
    # Calculate abundances using BBMap pileup
    mkdir -p abundance
    for bam in ${bams}; do
        base=\$(basename \$bam .bam)
        pileup.sh in=\$bam out=abundance/\${base}.cov.txt
        awk '{print \$1"\\t"\$5}' abundance/\${base}.cov.txt | grep -v '^#' > abundance/\${base}.abundance.txt
    done
:    
    input:
    tuple val(sample), path(contigs), path(bams)
    
    output:
    tuple val(sample), path("bins/*.fasta"), emit: bins
    path("${sample}_maxbin2.log"), emit: log
    
    script:
    """
    # Calculate abundances using BBMap pileup
    mkdir -p abundance
    for bam in ${bams}; do
        base=\$(basename \$bam .bam)
        pileup.sh in=\$bam out=abundance/\${base}.cov.txt
        awk '{print \$1"\\t"\$5}' abundance/\${base}.cov.txt | grep -v '^#' > abundance/\${base}.abundance.txt
    done
    
:    
    input:
    tuple val(sample), path(contigs), path(bams)
    
    output:
    tuple val(sample), path("bins/*.fasta"), emit: bins
    path("${sample}_maxbin2.log"), emit: log
    
    script:
    """
    # Calculate abundances using BBMap pileup
    mkdir -p abundance
    for bam in ${bams}; do
        base=\$(basename \$bam .bam)
        pileup.sh in=\$bam out=abundance/\${base}.cov.txt
        awk '{print \$1"\\t"\$5}' abundance/\${base}.cov.txt | grep -v '^#' > abundance/\${base}.abundance.txt
    done
    
    # Create abundance list file
    ls abundance/*.abundance.txt > abund_list.txt
    
:    
    input:
    tuple val(sample), path(contigs), path(bams)
    
    output:
    tuple val(sample), path("bins/*.fasta"), emit: bins
    path("${sample}_maxbin2.log"), emit: log
    
    script:
    """
    # Calculate abundances using BBMap pileup
    mkdir -p abundance
    for bam in ${bams}; do
        base=\$(basename \$bam .bam)
        pileup.sh in=\$bam out=abundance/\${base}.cov.txt
        awk '{print \$1"\\t"\$5}' abundance/\${base}.cov.txt | grep -v '^#' > abundance/\${base}.abundance.txt
    done
    
    # Create abundance list file
    ls abundance/*.abundance.txt > abund_list.txt
    
    # Create bins directory
    mkdir -p bins
:    
    input:
    tuple val(sample), path(contigs), path(bams)
    
    output:
    tuple val(sample), path("bins/*.fasta"), emit: bins
    path("${sample}_maxbin2.log"), emit: log
    
    script:
    """
    # Calculate abundances using BBMap pileup
    mkdir -p abundance
    for bam in ${bams}; do
        base=\$(basename \$bam .bam)
        pileup.sh in=\$bam out=abundance/\${base}.cov.txt
        awk '{print \$1"\\t"\$5}' abundance/\${base}.cov.txt | grep -v '^#' > abundance/\${base}.abundance.txt
    done
    
    # Create abundance list file
    ls abundance/*.abundance.txt > abund_list.txt
    
    # Create bins directory
    mkdir -p bins
    
    # Run MaxBin2
:    
    input:
    tuple val(sample), path(contigs), path(bams)
    
    output:
    tuple val(sample), path("bins/*.fasta"), emit: bins
    path("${sample}_maxbin2.log"), emit: log
    
    script:
    """
    # Calculate abundances using BBMap pileup
    mkdir -p abundance
    for bam in ${bams}; do
        base=\$(basename \$bam .bam)
        pileup.sh in=\$bam out=abundance/\${base}.cov.txt
        awk '{print \$1"\\t"\$5}' abundance/\${base}.cov.txt | grep -v '^#' > abundance/\${base}.abundance.txt
    done
    
    # Create abundance list file
    ls abundance/*.abundance.txt > abund_list.txt
    
    # Create bins directory
    mkdir -p bins
    
    # Run MaxBin2
    run_MaxBin.pl \\
        -contig ${contigs} \\
:    
    input:
    tuple val(sample), path(contigs), path(bams)
    
    output:
    tuple val(sample), path("bins/*.fasta"), emit: bins
    path("${sample}_maxbin2.log"), emit: log
    
    script:
    """
    # Calculate abundances using BBMap pileup
    mkdir -p abundance
    for bam in ${bams}; do
        base=\$(basename \$bam .bam)
        pileup.sh in=\$bam out=abundance/\${base}.cov.txt
        awk '{print \$1"\\t"\$5}' abundance/\${base}.cov.txt | grep -v '^#' > abundance/\${base}.abundance.txt
    done
    
    # Create abundance list file
    ls abundance/*.abundance.txt > abund_list.txt
    
    # Create bins directory
    mkdir -p bins
    
    # Run MaxBin2
    run_MaxBin.pl \\
        -contig ${contigs} \\
        -abund_list abund_list.txt \\
:    
    input:
    tuple val(sample), path(contigs), path(bams)
    
    output:
    tuple val(sample), path("bins/*.fasta"), emit: bins
    path("${sample}_maxbin2.log"), emit: log
    
    script:
    """
    # Calculate abundances using BBMap pileup
    mkdir -p abundance
    for bam in ${bams}; do
        base=\$(basename \$bam .bam)
        pileup.sh in=\$bam out=abundance/\${base}.cov.txt
        awk '{print \$1"\\t"\$5}' abundance/\${base}.cov.txt | grep -v '^#' > abundance/\${base}.abundance.txt
    done
    
    # Create abundance list file
    ls abundance/*.abundance.txt > abund_list.txt
    
    # Create bins directory
    mkdir -p bins
    
    # Run MaxBin2
    run_MaxBin.pl \\
        -contig ${contigs} \\
        -abund_list abund_list.txt \\
        -out bins/${sample}_maxbin \\
        -thread ${task.cpus} \\
:    
    input:
    tuple val(sample), path(contigs), path(bams)
    
    output:
    tuple val(sample), path("bins/*.fasta"), emit: bins
    path("${sample}_maxbin2.log"), emit: log
    
    script:
    """
    # Calculate abundances using BBMap pileup
    mkdir -p abundance
    for bam in ${bams}; do
        base=\$(basename \$bam .bam)
        pileup.sh in=\$bam out=abundance/\${base}.cov.txt
        awk '{print \$1"\\t"\$5}' abundance/\${base}.cov.txt | grep -v '^#' > abundance/\${base}.abundance.txt
    done
    
    # Create abundance list file
    ls abundance/*.abundance.txt > abund_list.txt
    
    # Create bins directory
    mkdir -p bins
    
    # Run MaxBin2
    run_MaxBin.pl \\
        -contig ${contigs} \\
        -abund_list abund_list.txt \\
        -out bins/${sample}_maxbin \\
        -thread ${task.cpus} \\
        -min_contig_length ${params.min_contig_length} \\
:    
    input:
    tuple val(sample), path(contigs), path(bams)
    
    output:
    tuple val(sample), path("bins/*.fasta"), emit: bins
    path("${sample}_maxbin2.log"), emit: log
    
    script:
    """
    # Calculate abundances using BBMap pileup
    mkdir -p abundance
    for bam in ${bams}; do
        base=\$(basename \$bam .bam)
        pileup.sh in=\$bam out=abundance/\${base}.cov.txt
        awk '{print \$1"\\t"\$5}' abundance/\${base}.cov.txt | grep -v '^#' > abundance/\${base}.abundance.txt
    done
    
    # Create abundance list file
    ls abundance/*.abundance.txt > abund_list.txt
    
    # Create bins directory
    mkdir -p bins
    
    # Run MaxBin2
    run_MaxBin.pl \\
        -contig ${contigs} \\
        -abund_list abund_list.txt \\
        -out bins/${sample}_maxbin \\
        -thread ${task.cpus} \\
        -min_contig_length ${params.min_contig_length} \\
        2>&1 | tee ${sample}_maxbin2.log
:    
    input:
    tuple val(sample), path(contigs), path(bams)
    
    output:
    tuple val(sample), path("bins/*.fasta"), emit: bins
    path("${sample}_maxbin2.log"), emit: log
    
    script:
    """
    # Calculate abundances using BBMap pileup
    mkdir -p abundance
    for bam in ${bams}; do
        base=\$(basename \$bam .bam)
        pileup.sh in=\$bam out=abundance/\${base}.cov.txt
        awk '{print \$1"\\t"\$5}' abundance/\${base}.cov.txt | grep -v '^#' > abundance/\${base}.abundance.txt
    done
    
    # Create abundance list file
    ls abundance/*.abundance.txt > abund_list.txt
    
    # Create bins directory
    mkdir -p bins
    
    # Run MaxBin2
    run_MaxBin.pl \\
        -contig ${contigs} \\
        -abund_list abund_list.txt \\
        -out bins/${sample}_maxbin \\
        -thread ${task.cpus} \\
        -min_contig_length ${params.min_contig_length} \\
        2>&1 | tee ${sample}_maxbin2.log
    
    # Ensure at least one output file exists
    if [ ! -f bins/${sample}_maxbin.*.fasta ]; then
        echo "No bins generated" > ${sample}_maxbin2.log
        touch bins/no_bins.fasta
    fi
    """
}
