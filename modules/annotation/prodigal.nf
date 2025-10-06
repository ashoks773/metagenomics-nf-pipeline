/*
========================================================================================
   Gene Prediction and Annotation Modules
========================================================================================
*/

process PRODIGAL {
    tag "$sample"
    label 'process_low'
    publishDir "${params.outdir}/05_gene_prediction/prodigal/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::prodigal=2.6.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/prodigal:2.6.3--h516909a_2' :
        'quay.io/biocontainers/prodigal:2.6.3--h516909a_2' }"
    
    input:
    tuple val(sample), path(contigs)
    
    output:
    tuple val(sample), path("${sample}_genes.fna"), emit: genes_fna
    tuple val(sample), path("${sample}_genes.faa"), emit: genes_faa
    tuple val(sample), path("${sample}_genes.gff"), emit: gff
    
    script:
    """
    prodigal \\
        -i ${contigs} \\
        -d ${sample}_genes.fna \\
        -a ${sample}_genes.faa \\
        -o ${sample}_genes.gff \\
        -f gff \\
        -p meta \\
        -q
    """
}

process KEGG_ANNOTATION {
    tag "$sample"
    label 'process_high'
    publishDir "${params.outdir}/08_functional_annotation/kegg/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::diamond=2.1.8" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/diamond:2.1.8--h43eeafb_0' :
        'quay.io/biocontainers/diamond:2.1.8--h43eeafb_0' }"
    
    input:
    tuple val(sample), path(genes_faa)
    path(kegg_db)
    
    output:
    tuple val(sample), path("${sample}_kegg_annotation.tsv"), emit: annotation
    path("${sample}_kegg.log"), emit: log
    
    script:
    """
    # Run DIAMOND BLASTP against KEGG
    diamond blastp \\
        --query ${genes_faa} \\
        --db ${kegg_db} \\
        --out ${sample}_kegg_annotation.tsv \\
        --outfmt 6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore stitle \\
        --threads ${task.cpus} \\
        --max-target-seqs 1 \\
        --evalue 1e-5 \\
        --sensitive \\
        2>&1 | tee ${sample}_kegg.log
    """
}

process CAZY_ANNOTATION {
    tag "$sample"
    label 'process_high'
    publishDir "${params.outdir}/08_functional_annotation/cazy/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::diamond=2.1.8" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/diamond:2.1.8--h43eeafb_0' :
        'quay.io/biocontainers/diamond:2.1.8--h43eeafb_0' }"
    
    input:
    tuple val(sample), path(genes_faa)
    path(cazy_db)
    
    output:
    tuple val(sample), path("${sample}_cazy_annotation.tsv"), emit: annotation
    path("${sample}_cazy.log"), emit: log
    
    script:
    """
    # Run DIAMOND BLASTP against CAZy
    diamond blastp \\
        --query ${genes_faa} \\
        --db ${cazy_db} \\
        --out ${sample}_cazy_annotation.tsv \\
        --outfmt 6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore stitle \\
        --threads ${task.cpus} \\
        --max-target-seqs 1 \\
        --evalue 1e-5 \\
        --sensitive \\
        2>&1 | tee ${sample}_cazy.log
    """
}

process FILTER_CONTIGS {
    tag "$sample"
    label 'process_low'
    publishDir "${params.outdir}/04_assembly/filtered_contigs/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::seqkit=2.4.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.4.0--h9ee0642_0' :
        'quay.io/biocontainers/seqkit:2.4.0--h9ee0642_0' }"
    
    input:
    tuple val(sample), path(contigs)
    val(min_length)
    
    output:
    tuple val(sample), path("${sample}_filtered_contigs.fa"), emit: contigs
    path("${sample}_filter_stats.txt"), emit: stats
    
    script:
    """
    # Filter contigs by length
    seqkit seq \\
        -m ${min_length} \\
        ${contigs} \\
        > ${sample}_filtered_contigs.fa
    
    # Generate statistics
    echo "Original contigs:" > ${sample}_filter_stats.txt
    seqkit stats ${contigs} >> ${sample}_filter_stats.txt
    echo "" >> ${sample}_filter_stats.txt
    echo "Filtered contigs (>= ${min_length} bp):" >> ${sample}_filter_stats.txt
    seqkit stats ${sample}_filtered_contigs.fa >> ${sample}_filter_stats.txt
    """
}
