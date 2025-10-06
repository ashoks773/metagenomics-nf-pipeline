/*
========================================================================================
   Assembly and Binning Sub-workflow
========================================================================================
   This sub-workflow handles assembly, binning, and MAG quality assessment
*/

include { MEGAHIT; MEGAHIT_COASSEMBLY } from '../modules/assembly/megahit'
include { SPADES } from '../modules/assembly/spades'
include { FILTER_CONTIGS } from '../modules/assembly/filter_contigs'
include { BOWTIE2_BUILD; BOWTIE2_ALIGN } from '../modules/mapping/bowtie2'
include { SAMTOOLS_SORT; SAMTOOLS_INDEX } from '../modules/mapping/samtools'
include { METABAT2 } from '../modules/binning/metabat2'
include { MAXBIN2 } from '../modules/binning/maxbin2'
include { CONCOCT } from '../modules/binning/concoct'
include { DASTOOL } from '../modules/binning/dastool'
include { CHECKM } from '../modules/binning/checkm'

workflow ASSEMBLY_BINNING {
    take:
    reads              // channel: [val(sample), path(reads1), path(reads2)]
    assembler          // val: 'megahit' or 'spades'
    coassembly         // val: true or false
    min_contig_length  // val: minimum contig length
    binning_tools      // val: comma-separated list of binning tools
    checkm_db          // path: CheckM database
    
    main:
    
    // Assembly
    if (coassembly) {
        // Co-assembly mode: combine all samples
        ch_all_reads = reads
            .map { sample, r1, r2 -> [r1, r2] }
            .collect()
        
        MEGAHIT_COASSEMBLY(ch_all_reads)
        ch_assembly = MEGAHIT_COASSEMBLY.out.contigs
            .map { contigs -> tuple('coassembly', contigs) }
    } else {
        // Individual assembly per sample
        if (assembler == 'megahit') {
            MEGAHIT(reads)
            ch_assembly = MEGAHIT.out.contigs
        } else if (assembler == 'spades') {
            SPADES(reads)
            ch_assembly = SPADES.out.contigs
        }
    }
    
    // Filter contigs by length
    FILTER_CONTIGS(ch_assembly, min_contig_length)
    ch_filtered_contigs = FILTER_CONTIGS.out.contigs
    
    // Build Bowtie2 index for contigs
    BOWTIE2_BUILD(ch_filtered_contigs)
    
    // Map reads back to contigs
    ch_mapping_input = reads
        .map { sample, r1, r2 -> tuple(sample, r1, r2) }
        .combine(BOWTIE2_BUILD.out.index.map { sample, idx -> tuple(sample, idx) }, by: 0)
    
    BOWTIE2_ALIGN(ch_mapping_input)
    
    // Sort and index BAM files
    SAMTOOLS_SORT(BOWTIE2_ALIGN.out.bam)
    SAMTOOLS_INDEX(SAMTOOLS_SORT.out.bam)
    
    // Collect all BAMs for each assembly
    ch_binning_input = ch_filtered_contigs
        .combine(SAMTOOLS_SORT.out.bam.groupTuple())
    
    // Binning with selected tools
    def tools = binning_tools.split(',')
    ch_all_bins = Channel.empty()
    
    if ('metabat2' in tools) {
        METABAT2(ch_binning_input)
        ch_all_bins = ch_all_bins.mix(METABAT2.out.bins)
    }
    
    if ('maxbin2' in tools) {
        MAXBIN2(ch_binning_input)
        ch_all_bins = ch_all_bins.mix(MAXBIN2.out.bins)
    }
    
    if ('concoct' in tools) {
        CONCOCT(ch_binning_input)
        ch_all_bins = ch_all_bins.mix(CONCOCT.out.bins)
    }
    
    // Integrate bins with DAS_Tool if multiple tools used
    if (tools.size() > 1) {
        ch_dastool_input = ch_all_bins
            .groupTuple()
            .combine(ch_filtered_contigs, by: 0)
        
        DASTOOL(ch_dastool_input)
        ch_final_bins = DASTOOL.out.bins
    } else {
        ch_final_bins = ch_all_bins
    }
    
    // Assess bin quality with CheckM
    CHECKM(ch_final_bins, checkm_db)
    
    emit:
    contigs = ch_filtered_contigs          // channel: [val(sample), path(contigs)]
    bins = ch_final_bins                   // channel: [val(sample), path(bins)]
    checkm_results = CHECKM.out.results    // channel: [val(sample), path(checkm_results)]
    bams = SAMTOOLS_SORT.out.bam          // channel: [val(sample), path(bam)]
}

workflow {
    // This workflow can be run standalone if needed
    // Example usage:
    // nextflow run workflows/assembly_binning.nf --input samples.csv --checkm_db /path/to/db
    
    if (params.input && params.checkm_db) {
        Channel
            .fromPath(params.input)
            .splitCsv(header: true)
            .map { row -> tuple(row.sample, file(row.fastq_1), file(row.fastq_2)) }
            .set { ch_input }
        
        ASSEMBLY_BINNING(
            ch_input,
            params.assembler ?: 'megahit',
            params.coassembly ?: false,
            params.min_contig_length ?: 1000,
            params.binning_tools ?: 'metabat2,maxbin2',
            params.checkm_db
        )
    }
}
