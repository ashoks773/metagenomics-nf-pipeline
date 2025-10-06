/*
========================================================================================
   Functional Profiling Sub-workflow
========================================================================================
   This sub-workflow handles functional profiling with HUMAnN
*/

include { HUMANN } from '../modules/functional/humann'

workflow FUNCTIONAL_PROFILING {
    take:
    reads              // channel: [val(sample), path(reads1), path(reads2)]
    nucleotide_db      // path: HUMAnN nucleotide database
    protein_db         // path: HUMAnN protein database
    
    main:
    // Run HUMAnN functional profiling
    HUMANN(reads, nucleotide_db, protein_db)
    
    // Collect all outputs for merging
    ch_all_genefamilies = HUMANN.out.genefamilies.collect()
    ch_all_pathabundance = HUMANN.out.pathabundance.collect()
    ch_all_pathcoverage = HUMANN.out.pathcoverage.collect()
    
    emit:
    genefamilies = HUMANN.out.genefamilies       // channel: [val(sample), path(genefamilies)]
    pathabundance = HUMANN.out.pathabundance     // channel: [val(sample), path(pathabundance)]
    pathcoverage = HUMANN.out.pathcoverage       // channel: [val(sample), path(pathcoverage)]
    all_genefamilies = ch_all_genefamilies       // channel: path(genefamilies)
    all_pathabundance = ch_all_pathabundance     // channel: path(pathabundance)
    all_pathcoverage = ch_all_pathcoverage       // channel: path(pathcoverage)
}

workflow {
    // This workflow can be run standalone if needed
    // Example usage:
    // nextflow run workflows/functional_profiling.nf --input samples.csv --humann_nucleotide_db /path/to/db --humann_protein_db /path/to/db
    
    if (params.input && params.humann_nucleotide_db && params.humann_protein_db) {
        Channel
            .fromPath(params.input)
            .splitCsv(header: true)
            .map { row -> tuple(row.sample, file(row.fastq_1), file(row.fastq_2)) }
            .set { ch_input }
        
        FUNCTIONAL_PROFILING(
            ch_input,
            params.humann_nucleotide_db,
            params.humann_protein_db
        )
    }
}
