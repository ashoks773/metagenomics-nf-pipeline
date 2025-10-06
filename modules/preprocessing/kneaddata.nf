/*
========================================================================================
   KneadData Process - Quality Filtering and Host Removal
========================================================================================
*/

process KNEADDATA {
    tag "$sample"
    label 'process_high'
    publishDir "${params.outdir}/01_kneaddata/${sample}", mode: params.publish_dir_mode
    
    conda (params.enable_conda ? "bioconda::kneaddata=0.12.0" : null)
    