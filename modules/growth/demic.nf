/*
========================================================================================
   Growth Rate and Clustering Modules
========================================================================================
*/

process DEMIC {
    tag "$sample"
    label 'process_medium'
    publishDir "${params.outdir}/10_growth_rates/demic/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::perl=5.32.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl:5.32.1' :
        'quay.io/biocontainers/perl:5.32.1' }"
    
    input:
    tuple val(sample), path(sam_files), path(bins)
    
    output:
    tuple val(sample), path("${sample}_growth_rates.txt"), emit: growth_rates
    path("${sample}_demic.log"), emit: log
    
    script:
    """
    # Create directories for DEMIC
    mkdir -p sam_dir
    mkdir -p bins_dir
    
    # Copy SAM files
    cp ${sam_files} sam_dir/
    
    # Copy bins
    cp ${bins} bins_dir/
    
    # Download DEMIC script if not available
    if [ ! -f DEMIC.pl ]; then
        wget https://sourceforge.net/projects/demic/files/DEMIC.pl/download -O DEMIC.pl
        chmod +x DEMIC.pl
    fi
    
    # Run DEMIC
    perl DEMIC.pl \\
        -S sam_dir \\
        -F bins_dir \\
        -O ${sample}_demic_output \\
        2>&1 | tee ${sample}_demic.log
    
    # Consolidate results
    if [ -f ${sample}_demic_output/growth_rates.txt ]; then
        cp ${sample}_demic_output/growth_rates.txt ${sample}_growth_rates.txt
    else
        echo "No growth rates calculated" > ${sample}_growth_rates.txt
    fi
    """
}

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

process FASTQC {
    tag "$sample"
    label 'process_low'
    publishDir "${params.outdir}/qc/fastqc/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::fastqc=0.12.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastqc:0.12.1--hdfd78af_0' :
        'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0' }"
    
    input:
    tuple val(sample), path(reads1), path(reads2)
    
    output:
    tuple val(sample), path("*.html"), emit: html
    tuple val(sample), path("*.zip"), emit: zip
    
    script:
    """
    fastqc \\
        --threads ${task.cpus} \\
        --quiet \\
        ${reads1} ${reads2}
    """
}

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

process SPADES {
    tag "$sample"
    label 'process_high'
    publishDir "${params.outdir}/04_assembly/spades/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::spades=3.15.5" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/spades:3.15.5--h95f258a_1' :
        'quay.io/biocontainers/spades:3.15.5--h95f258a_1' }"
    
    input:
    tuple val(sample), path(reads1), path(reads2)
    
    output:
    tuple val(sample), path("${sample}_contigs.fa"), emit: contigs
    tuple val(sample), path("${sample}_scaffolds.fa"), emit: scaffolds
    path("${sample}_spades.log"), emit: log
    
    script:
    """
    spades.py \\
        --meta \\
        -1 ${reads1} \\
        -2 ${reads2} \\
        -o spades_output \\
        -t ${task.cpus} \\
        -m $((task.memory.toGiga()))
    
    # Copy outputs
    cp spades_output/contigs.fasta ${sample}_contigs.fa
    cp spades_output/scaffolds.fasta ${sample}_scaffolds.fa
    cp spades_output/spades.log ${sample}_spades.log
    """
}
