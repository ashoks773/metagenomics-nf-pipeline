/*
========================================================================================
   Read Mapping Modules - BWA and Bowtie2
========================================================================================
*/

process BWA_INDEX {
    tag "$sample"
    label 'process_medium'
    publishDir "${params.outdir}/06_gene_quantification/bwa_index/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::bwa=0.7.17" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bwa:0.7.17--h7132678_9' :
        'quay.io/biocontainers/bwa:0.7.17--h7132678_9' }"
    
    input:
    tuple val(sample), path(fasta)
    
    output:
    tuple val(sample), path("${fasta}*"), emit: index
    
    script:
    """
    bwa index ${fasta}
    """
}

process BWA_MEM {
    tag "$sample"
    label 'process_high'
    publishDir "${params.outdir}/06_gene_quantification/bwa_mapped/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::bwa=0.7.17 bioconda::samtools=1.17" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-fe8faa35dbf6dc65a0f7f5d4ea12e31a79f73e40:219b6c272b25e7e642ae3ff0bf0c5c81a5135ab4-0' :
        'quay.io/biocontainers/mulled-v2-fe8faa35dbf6dc65a0f7f5d4ea12e31a79f73e40:219b6c272b25e7e642ae3ff0bf0c5c81a5135ab4-0' }"
    
    input:
    tuple val(sample), path(reads1), path(reads2), path(index)
    
    output:
    tuple val(sample), path("${sample}_mapped.bam"), emit: bam
    path("${sample}_bwa.log"), emit: log
    
    script:
    def index_base = index[0].toString() - ~/.amb|.ann|.bwt|.pac|.sa$/
    """
    bwa mem \\
        -t ${task.cpus} \\
        ${index_base} \\
        ${reads1} \\
        ${reads2} \\
        2> ${sample}_bwa.log \\
        | samtools view -b -o ${sample}_mapped.bam -
    """
}

process BOWTIE2_BUILD {
    tag "$sample"
    label 'process_medium'
    publishDir "${params.outdir}/07_contig_mapping/bowtie2_index/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::bowtie2=2.5.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bowtie2:2.5.1--py310h8d7afc0_0' :
        'quay.io/biocontainers/bowtie2:2.5.1--py310h8d7afc0_0' }"
    
    input:
    tuple val(sample), path(fasta)
    
    output:
    tuple val(sample), path("${sample}_bowtie2_index*"), emit: index
    
    script:
    """
    bowtie2-build \\
        --threads ${task.cpus} \\
        ${fasta} \\
        ${sample}_bowtie2_index
    """
}

process BOWTIE2_ALIGN {
    tag "$sample"
    label 'process_high'
    publishDir "${params.outdir}/07_contig_mapping/bowtie2_mapped/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::bowtie2=2.5.1 bioconda::samtools=1.17" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-ac74a7f02cebcfcc07d8e8d1d750af9c83b4d45a:a0ffedb52808e102887f6ce600d092675bf3528a-0' :
        'quay.io/biocontainers/mulled-v2-ac74a7f02cebcfcc07d8e8d1d750af9c83b4d45a:a0ffedb52808e102887f6ce600d092675bf3528a-0' }"
    
    input:
    tuple val(sample), path(reads1), path(reads2), path(index)
    
    output:
    tuple val(sample), path("${sample}_mapped.bam"), emit: bam
    tuple val(sample), path("${sample}_mapped.sam"), emit: sam
    path("${sample}_bowtie2.log"), emit: log
    
    script:
    def index_base = index[0].toString() - ~/.1.bt2|.2.bt2|.3.bt2|.4.bt2|.rev.1.bt2|.rev.2.bt2$/
    """
    bowtie2 \\
        -x ${index_base} \\
        -1 ${reads1} \\
        -2 ${reads2} \\
        --threads ${task.cpus} \\
        --no-unal \\
        -S ${sample}_mapped.sam \\
        2> ${sample}_bowtie2.log
    
    # Convert SAM to BAM
    samtools view \\
        -b \\
        -@ ${task.cpus} \\
        -o ${sample}_mapped.bam \\
        ${sample}_mapped.sam
    """
}

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
