process CDHIT {
    label 'process_high'
    publishDir "${params.outdir}/07_nr_genes/cdhit", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::cd-hit=4.8.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/cd-hit:4.8.1--h5b5514e_7' :
        'quay.io/biocontainers/cd-hit:4.8.1--h5b5514e_7' }"
    
    input:
    path(genes_list)
    
    output:
    path("nr_genes.fna"), emit: clustered
    path("nr_genes.fna.clstr"), emit: clusters
    path("cdhit.log"), emit: log
    
    script:
    """
    # Concatenate all gene files
    cat ${genes_list} > all_genes.fna
    
    # Run CD-HIT-EST for nucleotide sequences
    cd-hit-est \\
        -i all_genes.fna \\
        -o nr_genes.fna \\
        -c 0.95 \\
        -n 10 \\
        -aS 0.9 \\
        -d 0 \\
        -T ${task.cpus} \\
        -M $((task.memory.toMega() * 0.9)) \\
        2>&1 | tee cdhit.log
    """
}

