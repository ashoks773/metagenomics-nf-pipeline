/*
========================================================================================
   HUMAnN Process - Functional Profiling
========================================================================================
*/

process HUMANN {
    tag "$sample"
    label 'process_high'
    publishDir "${params.outdir}/03_functional/humann/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::humann=3.6" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/humann:3.6--pyh7cba7a3_0' :
        'quay.io/biocontainers/humann:3.6--pyh7cba7a3_0' }"
    
    input:
    tuple val(sample), path(reads1), path(reads2)
    path(nucleotide_db)
    path(protein_db)
    
    output:
    tuple val(sample), path("${sample}_genefamilies.tsv"), emit: genefamilies
    tuple val(sample), path("${sample}_pathabundance.tsv"), emit: pathabundance
    tuple val(sample), path("${sample}_pathcoverage.tsv"), emit: pathcoverage
    
    script:
    """
    # Concatenate reads for HUMAnN
    cat ${reads1} ${reads2} > ${sample}_combined.fastq.gz
    
    # Run HUMAnN
    humann \\
        --input ${sample}_combined.fastq.gz \\
        --output humann_output \\
        --nucleotide-database ${nucleotide_db} \\
        --protein-database ${protein_db} \\
        --threads ${task.cpus} \\
        --memory-use maximum \\
        --output-basename ${sample}
    
    # Move outputs
    mv humann_output/${sample}_genefamilies.tsv .
    mv humann_output/${sample}_pathabundance.tsv .
    mv humann_output/${sample}_pathcoverage.tsv .
    
    # Clean up
    rm ${sample}_combined.fastq.gz
    rm -rf humann_output
    """
}
