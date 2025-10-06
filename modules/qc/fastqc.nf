process FASTQC {
    tag "$sample"
    label 'process_low'
    publishDir "${params.outdir}/qc/fastqc/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::fastqc=0.12.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastqc:0.12.1--hdfd78af_0' :
        'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0' }"
    
    input:
    tuple val(sample), path(reads1), path(reads2)
    
    output:
    tuple val(sample), path("*.html"), emit: html
    tuple val(sample), path("*.zip"), emit: zip
    
    script:
    """
    fastqc \\
        --threads ${task.cpus} \\
        --quiet \\
        ${reads1} ${reads2}
    """
}


