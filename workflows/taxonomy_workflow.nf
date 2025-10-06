/*
========================================================================================
   Taxonomy Profiling Sub-workflow
========================================================================================
   This sub-workflow handles taxonomic profiling with MetaPhlAn
*/

include { METAPHLAN } from '../modules/taxonomy/metaphlan'

workflow TAXONOMY_PROFILING {
    take:
    reads           // channel: [val(sample), path(reads1), path(reads2)]
    metaphlan_db    // path: MetaPhlAn database
    
    main:
    // Run MetaPhlAn taxonomic profiling
    METAPHLAN(reads, metaphlan_db)
    
    // Collect all profiles for merging
    ch_all_profiles = METAPHLAN.out.profile.collect()
    
    emit:
    profiles = METAPHLAN.out.profile        // channel: [val(sample), path(profile)]
    bowtie2out = METAPHLAN.out.bowtie2out  // channel: [val(sample), path(bowtie2)]
    all_profiles = ch_all_profiles          // channel: path(profiles)
}

workflow {
    // This workflow can be run standalone if needed
    // Example usage:
    // nextflow run workflows/taxonomy_profiling.nf --input samples.csv --metaphlan_db /path/to/db
    
    if (params.input && params.metaphlan_db) {
        Channel
            .fromPath(params.input)
            .splitCsv(header: true)
            .map { row -> tuple(row.sample, file(row.fastq_1), file(row.fastq_2)) }
            .set { ch_input }
        
        TAXONOMY_PROFILING(
            ch_input,
            params.metaphlan_db
        )
    }
}
