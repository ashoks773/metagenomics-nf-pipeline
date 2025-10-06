process MULTIQC {
    label 'process_low'
    publishDir "${params.outdir}/qc/multiqc", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::multiqc=1.15" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.15--pyhdfd78af_0' :
        'quay.io/biocontainers/multiqc:1.15--pyhdfd78af_0' }"
    
    input:
    path(multiqc_files)
    
    output:
    path("multiqc_report.html"), emit: report
    path("multiqc_data"), emit: data
    
    script:
    """
    multiqc \\
        --force \\
        --title "Metagenomics Pipeline Report" \\
        --filename multiqc_report.html \\
        .
    """
}

