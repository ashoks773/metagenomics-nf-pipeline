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

