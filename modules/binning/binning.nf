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

process MAXBIN2 {
    tag "$sample"
    label 'process_medium'
    publishDir "${params.outdir}/09_binning/maxbin2/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::maxbin2=2.2.7" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/maxbin2:2.2.7--h7d875b9_3' :
        'quay.io/biocontainers/maxbin2:2.2.7--h7d875b9_3' }"
    
    input:
    tuple val(sample), path(contigs), path(bams)
    
    output:
    tuple val(sample), path("bins/*.fasta"), emit: bins
    path("${sample}_maxbin2.log"), emit: log
    
    script:
    """
    # Calculate abundances using BBMap pileup
    mkdir -p abundance
    for bam in ${bams}; do
        base=\$(basename \$bam .bam)
        pileup.sh in=\$bam out=abundance/\${base}.cov.txt
        awk '{print \$1"\\t"\$5}' abundance/\${base}.cov.txt | grep -v '^#' > abundance/\${base}.abundance.txt
    done
    
    # Create abundance list file
    ls abundance/*.abundance.txt > abund_list.txt
    
    # Create bins directory
    mkdir -p bins
    
    # Run MaxBin2
    run_MaxBin.pl \\
        -contig ${contigs} \\
        -abund_list abund_list.txt \\
        -out bins/${sample}_maxbin \\
        -thread ${task.cpus} \\
        -min_contig_length ${params.min_contig_length} \\
        2>&1 | tee ${sample}_maxbin2.log
    
    # Ensure at least one output file exists
    if [ ! -f bins/${sample}_maxbin.*.fasta ]; then
        echo "No bins generated" > ${sample}_maxbin2.log
        touch bins/no_bins.fasta
    fi
    """
}

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

process DASTOOL {
    tag "$sample"
    label 'process_medium'
    publishDir "${params.outdir}/09_binning/dastool/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::das_tool=1.1.5" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/das_tool:1.1.5--r42hdfd78af_0' :
        'quay.io/biocontainers/das_tool:1.1.5--r42hdfd78af_0' }"
    
    input:
    tuple val(sample), path(bins_list), path(contigs)
    
    output:
    tuple val(sample), path("${sample}_DASTool_bins/*.fa"), emit: bins
    path("${sample}_DASTool_summary.tsv"), emit: summary
    path("${sample}_dastool.log"), emit: log
    
    script:
    def bin_dirs = bins_list.collect{ it }.join(',')
    """
    # Create scaffold2bin files for each binning method
    for bin_file in ${bins_list}; do
        method=\$(echo \$bin_file | cut -d'_' -f2)
        grep ">" \$bin_file | sed 's/>//' | awk -v bin="\$(basename \$bin_file .fa)" '{print \$1"\\t"bin}' >> \${method}_scaffolds2bin.tsv
    done
    
    # Combine all scaffold2bin files
    bin_methods=\$(ls *_scaffolds2bin.tsv | cut -d'_' -f1 | tr '\\n' ',' | sed 's/,\$//')
    bin_files=\$(ls *_scaffolds2bin.tsv | tr '\\n' ',' | sed 's/,\$//')
    
    # Run DAS_Tool
    DAS_Tool \\
        -i \${bin_files} \\
        -l \${bin_methods} \\
        -c ${contigs} \\
        -o ${sample}_DASTool \\
        --threads ${task.cpus} \\
        --write_bins 1 \\
        --search_engine diamond \\
        2>&1 | tee ${sample}_dastool.log
    
    # Ensure output directory exists
    if [ ! -d "${sample}_DASTool_bins" ]; then
        mkdir -p ${sample}_DASTool_bins
        touch ${sample}_DASTool_bins/no_bins.fa
    fi
    
    # Create summary if it doesn't exist
    if [ ! -f "${sample}_DASTool_summary.tsv" ]; then
        touch ${sample}_DASTool_summary.tsv
    fi
    """
}

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
