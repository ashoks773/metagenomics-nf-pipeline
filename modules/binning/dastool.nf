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

