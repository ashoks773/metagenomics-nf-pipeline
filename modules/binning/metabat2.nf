/*
========================================================================================
   MetaBAT2 Process - Genome Binning
========================================================================================
*/

process METABAT2 {
    tag "$sample"
    label 'process_medium'
    publishDir "${params.outdir}/09_binning/metabat2/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::metabat2=2.15" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metabat2:2.15--h986a166_1' :
        'quay.io/biocontainers/metabat2:2.15--h986a166_1' }"
    
    input:
    tuple val(sample), path(contigs), path(bams)
    
    output:
    tuple val(sample), path("bins/*.fa"), emit: bins
    tuple val(sample), path("${sample}_depth.txt"), emit: depth
    path("${sample}_metabat2.log"), emit: log
    
    script:
    """
    # Calculate contig depths
    jgi_summarize_bam_contig_depths \\
        --outputDepth ${sample}_depth.txt \\
        ${bams}
    
    # Create bins directory
    mkdir -p bins
    
    # Run MetaBAT2
    metabat2 \\
        -i ${contigs} \\
        -a ${sample}_depth.txt \\
        -o bins/${sample}_bin \\
        -t ${task.cpus} \\
        -m ${params.min_contig_length} \\
        2>&1 | tee ${sample}_metabat2.log
    
    # Ensure at least one output file exists
    if [ ! -f bins/${sample}_bin.*.fa ]; then
        echo "No bins generated" > ${sample}_metabat2.log
        touch bins/no_bins.fa
    fi
    """
}

