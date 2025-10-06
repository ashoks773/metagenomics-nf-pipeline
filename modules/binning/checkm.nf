process CHECKM {
    tag "$sample"
    label 'process_high'
    publishDir "${params.outdir}/09_binning/checkm/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::checkm-genome=1.2.2" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/checkm-genome:1.2.2--pyhdfd78af_1' :
        'quay.io/biocontainers/checkm-genome:1.2.2--pyhdfd78af_1' }"
    
    input:
    tuple val(sample), path(bins)
    path(checkm_db)
    
    output:
    tuple val(sample), path("${sample}_checkm_results.tsv"), emit: results
    path("${sample}_checkm.log"), emit: log
    
    script:
    """
    # Set CheckM database location
    echo "${checkm_db}" | checkm data setRoot "${checkm_db}"
    
    # Create bins directory and copy bins
    mkdir -p bins_input
    cp ${bins} bins_input/
    
    # Run CheckM lineage workflow
    checkm lineage_wf \\
        -x fa \\
        bins_input \\
        checkm_output \\
        -t ${task.cpus} \\
        --pplacer_threads ${task.cpus} \\
        2>&1 | tee ${sample}_checkm.log
    
    # Generate quality report
    checkm qa \\
        checkm_output/lineage.ms \\
        checkm_output \\
        -o 2 \\
        --tab_table \\
        -f ${sample}_checkm_results.tsv \\
        -t ${task.cpus}
    
    # Filter bins by quality
    awk -F'\\t' 'NR==1 || (\$12 >= ${params.min_bin_completeness} && \$13 <= ${params.max_bin_contamination})' \\
        ${sample}_checkm_results.tsv > ${sample}_checkm_filtered.tsv
    """
}
