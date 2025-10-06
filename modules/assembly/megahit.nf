/*
========================================================================================
   MEGAHIT Process - Metagenomic Assembly
========================================================================================
*/

process MEGAHIT {
    tag "$sample"
    label 'process_high'
    publishDir "${params.outdir}/04_assembly/megahit/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::megahit=1.2.9" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/megahit:1.2.9--h2e03b76_1' :
        'quay.io/biocontainers/megahit:1.2.9--h2e03b76_1' }"
    
    input:
    tuple val(sample), path(reads1), path(reads2)
    
    output:
    tuple val(sample), path("${sample}_contigs.fa"), emit: contigs
    path("${sample}_megahit.log"), emit: log
    
    script:
    """
    # Run MEGAHIT assembly
    megahit \\
        -1 ${reads1} \\
        -2 ${reads2} \\
        -o megahit_output \\
        --out-prefix ${sample} \\
        -t ${task.cpus} \\
        --min-contig-len ${params.min_contig_length}
    
    # Copy final contigs
    cp megahit_output/${sample}.contigs.fa ${sample}_contigs.fa
    
    # Copy log
    cp megahit_output/log ${sample}_megahit.log
    """
}

process MEGAHIT_COASSEMBLY {
    label 'process_high'
    publishDir "${params.outdir}/04_assembly/megahit_coassembly", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::megahit=1.2.9" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/megahit:1.2.9--h2e03b76_1' :
        'quay.io/biocontainers/megahit:1.2.9--h2e03b76_1' }"
    
    input:
    tuple path(reads1_list), path(reads2_list)
    
    output:
    path("coassembly_contigs.fa"), emit: contigs
    path("coassembly_megahit.log"), emit: log
    
    script:
    def r1 = reads1_list.collect{ it.toString() }.join(',')
    def r2 = reads2_list.collect{ it.toString() }.join(',')
    """
    # Run MEGAHIT co-assembly
    megahit \\
        -1 ${r1} \\
        -2 ${r2} \\
        -o megahit_output \\
        --out-prefix coassembly \\
        -t ${task.cpus} \\
        --min-contig-len ${params.min_contig_length}
    
    # Copy final contigs
    cp megahit_output/coassembly.contigs.fa coassembly_contigs.fa
    
    # Copy log
    cp megahit_output/log coassembly_megahit.log
    """
}
