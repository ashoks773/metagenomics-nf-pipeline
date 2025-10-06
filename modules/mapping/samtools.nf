process SAMTOOLS_SORT {
    tag "$sample"
    label 'process_medium'
    publishDir "${params.outdir}/07_contig_mapping/sorted/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::samtools=1.17" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.17--hd87286a_1' :
        'quay.io/biocontainers/samtools:1.17--hd87286a_1' }"
    
    input:
    tuple val(sample), path(bam)
    
    output:
    tuple val(sample), path("${sample}_sorted.bam"), emit: bam
    tuple val(sample), path("${sample}_sorted.sam"), emit: sam
    
    script:
    """
    # Sort BAM
    samtools sort \\
        -@ ${task.cpus} \\
        -o ${sample}_sorted.bam \\
        ${bam}
    
    # Convert sorted BAM to SAM (needed for DEMIC)
    samtools view \\
        -h \\
        -@ ${task.cpus} \\
        -o ${sample}_sorted.sam \\
        ${sample}_sorted.bam
    """
}

process SAMTOOLS_INDEX {
    tag "$sample"
    label 'process_low'
    publishDir "${params.outdir}/07_contig_mapping/indexed/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::samtools=1.17" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.17--hd87286a_1' :
        'quay.io/biocontainers/samtools:1.17--hd87286a_1' }"
    
    input:
    tuple val(sample), path(bam)
    
    output:
    tuple val(sample), path("${bam}.bai"), emit: bai
    
    script:
    """
    samtools index \\
        -@ ${task.cpus} \\
        ${bam}
    """
}

