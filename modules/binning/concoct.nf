process CONCOCT {
    tag "$sample"
    label 'process_medium'
    publishDir "${params.outdir}/09_binning/concoct/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::concoct=1.1.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/concoct:1.1.0--py27h88e4a8a_0' :
        'quay.io/biocontainers/concoct:1.1.0--py27h88e4a8a_0' }"
    
    input:
    tuple val(sample), path(contigs), path(bams)
    
    output:
    tuple val(sample), path("bins/*.fa"), emit: bins
    path("${sample}_concoct.log"), emit: log
    
    script:
    """
    # Cut contigs into 10kb chunks
    cut_up_fasta.py \\
        ${contigs} \\
        -c 10000 \\
        -o 0 \\
        --merge_last \\
        -b contigs_10K.bed \\
        > contigs_10K.fa
    
    # Generate coverage table
    concoct_coverage_table.py \\
        contigs_10K.bed \\
        ${bams} \\
        > coverage_table.tsv
    
    # Run CONCOCT
    concoct \\
        --composition_file contigs_10K.fa \\
        --coverage_file coverage_table.tsv \\
        -b concoct_output/ \\
        -t ${task.cpus} \\
        2>&1 | tee ${sample}_concoct.log
    
    # Merge chunked contigs
    merge_cutup_clustering.py \\
        concoct_output/clustering_gt1000.csv \\
        > concoct_output/clustering_merged.csv
    
    # Extract bins
    mkdir -p bins
    extract_fasta_bins.py \\
        ${contigs} \\
        concoct_output/clustering_merged.csv \\
        --output_path bins/
    
    # Rename bins to match naming convention
    for bin in bins/*.fa; do
        if [ -f "\$bin" ]; then
            newname=\$(echo \$bin | sed 's/\\.fa/_concoct.fa/')
            mv \$bin \$newname
        fi
    done
    
    # Ensure at least one output file exists
    if [ ! -f bins/*.fa ]; then
        echo "No bins generated" > ${sample}_concoct.log
        touch bins/no_bins.fa
    fi
    """
}
