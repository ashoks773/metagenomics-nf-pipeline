/*
========================================================================================
   MetaPhlAn Process - Taxonomic Profiling
========================================================================================
*/

process METAPHLAN {
    tag "$sample"
    label 'process_medium'
    publishDir "${params.outdir}/02_taxonomy/metaphlan/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::metaphlan=4.0.6" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metaphlan:4.0.6--pyhca03a8a_0' :
        'quay.io/biocontainers/metaphlan:4.0.6--pyhca03a8a_0' }"
    
    input:
    tuple val(sample), path(reads1), path(reads2)
    path(metaphlan_db)
    
    output:
    tuple val(sample), path("${sample}_metaphlan_profile.txt"), emit: profile
    tuple val(sample), path("${sample}_metaphlan.bowtie2.bz2"), emit: bowtie2out
    
    script:
    """
    # Concatenate reads for MetaPhlAn
    cat ${reads1} ${reads2} > ${sample}_combined.fastq.gz
    
    # Run MetaPhlAn
    metaphlan \\
        ${sample}_combined.fastq.gz \\
        --input_type fastq \\
        --nproc ${task.cpus} \\
        --bowtie2db ${metaphlan_db} \\
        --bowtie2out ${sample}_metaphlan.bowtie2.bz2 \\
        --output_file ${sample}_metaphlan_profile.txt
    
    # Clean up
    rm ${sample}_combined.fastq.gz
    """
}
