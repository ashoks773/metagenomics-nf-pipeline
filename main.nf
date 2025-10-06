#!/usr/bin/env nextflow

/*
========================================================================================
   Comprehensive Metagenomic Analysis Pipeline
========================================================================================
   Author: Based on workflows by Ashok K. Sharma
   Description: Complete pipeline for metagenomic data analysis from raw reads to
                functional/taxonomic annotation and growth rate calculation
   Version: 1.0.0
========================================================================================
*/

nextflow.enable.dsl=2

// Print pipeline header
def helpMessage() {
    log.info"""
    ================================================================
    Comprehensive Metagenomic Analysis Pipeline v${workflow.manifest.version}
    ================================================================
    
    Usage:
    nextflow run main.nf --input samplesheet.csv --outdir results [options]
    
    Mandatory arguments:
      --input                Path to comma-separated file containing sample info
      --outdir               Output directory for results
      
    Reference Databases (at least one required):
      --host_genome          Path to host genome for decontamination (optional)
      --metaphlan_db         Path to MetaPhlAn database
      --humann_protein_db    Path to HUMAnN protein database
      --humann_nucleotide_db Path to HUMAnN nucleotide database
      --checkm_db            Path to CheckM database directory
      --kegg_db              Path to KEGG database for BLAST
      --cazy_db              Path to CAZy database for annotation
      
    Pipeline Options:
      --skip_qc              Skip quality control with FastQC [false]
      --skip_kneaddata       Skip KneadData (assumes clean reads) [false]
      --skip_assembly        Skip assembly step [false]
      --skip_binning         Skip MAG binning [false]
      --skip_growth_rates    Skip growth rate calculation [false]
      --skip_functional      Skip functional annotation [false]
      --skip_taxonomic       Skip taxonomic profiling [false]
      
    Assembly Options:
      --assembler            Assembly tool: 'megahit' or 'spades' [megahit]
      --coassembly           Perform co-assembly of all samples [false]
      --min_contig_length    Minimum contig length [1000]
      
    Binning Options:
      --binning_tools        Comma-separated list: metabat2,maxbin2,concoct [metabat2,maxbin2]
      --min_bin_completeness Minimum bin completeness [50]
      --max_bin_contamination Maximum bin contamination [10]
      
    Computational Resources:
      --max_cpus             Maximum CPUs per process [16]
      --max_memory           Maximum memory per process [128.GB]
      --max_time             Maximum time per process [240.h]
      
    Profile Options:
      -profile               Configuration profile: docker, singularity, conda, awsbatch, slurm
      
    Other:
      --help                 Display this help message
    """.stripIndent()
}

// Show help message
if (params.help) {
    helpMessage()
    exit 0
}

// Validate mandatory parameters
if (!params.input) {
    exit 1, "ERROR: Please provide --input samplesheet.csv"
}
if (!params.outdir) {
    exit 1, "ERROR: Please provide --outdir for results"
}

/*
========================================================================================
   PARAMETER DEFAULTS
========================================================================================
*/

params.input = null
params.outdir = './results'
params.help = false

// Reference databases
params.host_genome = null
params.metaphlan_db = null
params.humann_protein_db = null
params.humann_nucleotide_db = null
params.checkm_db = null
params.kegg_db = null
params.cazy_db = null
params.ardb_db = null

// Pipeline control
params.skip_qc = false
params.skip_kneaddata = false
params.skip_assembly = false
params.skip_binning = false
params.skip_growth_rates = false
params.skip_functional = false
params.skip_taxonomic = false

// Assembly parameters
params.assembler = 'megahit'
params.coassembly = false
params.min_contig_length = 1000

// Binning parameters
params.binning_tools = 'metabat2,maxbin2'
params.min_bin_completeness = 50
params.max_bin_contamination = 10

// Resource limits
params.max_cpus = 16
params.max_memory = 128.GB
params.max_time = 240.h

/*
========================================================================================
   IMPORT MODULES
========================================================================================
*/

include { FASTQC } from './modules/qc/fastqc'
include { MULTIQC } from './modules/qc/multiqc'
include { KNEADDATA } from './modules/preprocessing/kneaddata'
include { METAPHLAN } from './modules/taxonomy/metaphlan'
include { HUMANN } from './modules/functional/humann'
include { MEGAHIT } from './modules/assembly/megahit'
include { MEGAHIT_COASSEMBLY } from './modules/assembly/megahit'
include { SPADES } from './modules/assembly/spades'
include { FILTER_CONTIGS } from './modules/assembly/filter_contigs'
include { PRODIGAL } from './modules/annotation/prodigal'
include { BWA_INDEX; BWA_MEM } from './modules/mapping/bwa'
include { SAMTOOLS_SORT; SAMTOOLS_INDEX } from './modules/mapping/samtools'
include { BOWTIE2_BUILD; BOWTIE2_ALIGN } from './modules/mapping/bowtie2'
include { METABAT2 } from './modules/binning/metabat2'
include { MAXBIN2 } from './modules/binning/maxbin2'
include { CONCOCT } from './modules/binning/concoct'
include { DASTOOL } from './modules/binning/dastool'
include { CHECKM } from './modules/binning/checkm'
include { CDHIT } from './modules/clustering/cdhit'
include { KEGG_ANNOTATION } from './modules/annotation/kegg'
include { CAZY_ANNOTATION } from './modules/annotation/cazy'
include { DEMIC } from './modules/growth/demic'

/*
========================================================================================
   MAIN WORKFLOW
========================================================================================
*/

workflow {
    
    // Parse input samplesheet
    ch_input = Channel
        .fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true)
        .map { row -> 
            def sample_id = row.sample
            def fastq_1 = file(row.fastq_1, checkIfExists: true)
            def fastq_2 = file(row.fastq_2, checkIfExists: true)
            return tuple(sample_id, fastq_1, fastq_2)
        }
    
    /*
    ================================================================================
       STEP 1: QUALITY CONTROL
    ================================================================================
    */
    
    if (!params.skip_qc) {
        FASTQC(ch_input)
        ch_fastqc_results = FASTQC.out.zip.collect()
    }
    
    /*
    ================================================================================
       STEP 2: READ PREPROCESSING (KneadData)
    ================================================================================
    */
    
    if (!params.skip_kneaddata && params.host_genome) {
        KNEADDATA(ch_input, params.host_genome)
        ch_clean_reads = KNEADDATA.out.reads
        ch_kneaddata_logs = KNEADDATA.out.log
    } else {
        ch_clean_reads = ch_input
    }
    
    /*
    ================================================================================
       STEP 3: TAXONOMIC PROFILING (MetaPhlAn)
    ================================================================================
    */
    
    if (!params.skip_taxonomic && params.metaphlan_db) {
        METAPHLAN(ch_clean_reads, params.metaphlan_db)
        ch_metaphlan_profiles = METAPHLAN.out.profile
    }
    
    /*
    ================================================================================
       STEP 4: FUNCTIONAL PROFILING (HUMAnN)
    ================================================================================
    */
    
    if (!params.skip_functional && params.humann_protein_db) {
        HUMANN(
            ch_clean_reads, 
            params.humann_nucleotide_db,
            params.humann_protein_db
        )
        ch_humann_genefamilies = HUMANN.out.genefamilies
        ch_humann_pathabundance = HUMANN.out.pathabundance
        ch_humann_pathcoverage = HUMANN.out.pathcoverage
    }
    
    /*
    ================================================================================
       STEP 5: METAGENOMIC ASSEMBLY
    ================================================================================
    */
    
    if (!params.skip_assembly) {
        if (params.coassembly) {
            // Co-assembly: combine all samples
            ch_all_reads = ch_clean_reads
                .map { sample, r1, r2 -> [r1, r2] }
                .collect()
            
            if (params.assembler == 'megahit') {
                MEGAHIT_COASSEMBLY(ch_all_reads)
                ch_assembly = MEGAHIT_COASSEMBLY.out.contigs
                    .map { contigs -> tuple('coassembly', contigs) }
            }
        } else {
            // Individual assembly per sample
            if (params.assembler == 'megahit') {
                MEGAHIT(ch_clean_reads)
                ch_assembly = MEGAHIT.out.contigs
            } else if (params.assembler == 'spades') {
                SPADES(ch_clean_reads)
                ch_assembly = SPADES.out.contigs
            }
        }
        
        // Filter contigs by length
        FILTER_CONTIGS(ch_assembly, params.min_contig_length)
        ch_filtered_contigs = FILTER_CONTIGS.out.contigs
        
    } else {
        ch_filtered_contigs = Channel.empty()
    }
    
    /*
    ================================================================================
       STEP 6: GENE PREDICTION AND QUANTIFICATION
    ================================================================================
    */
    
    if (!params.skip_assembly) {
        // Gene prediction with Prodigal
        PRODIGAL(ch_filtered_contigs)
        ch_genes_fna = PRODIGAL.out.genes_fna
        ch_genes_faa = PRODIGAL.out.genes_faa
        
        // Map reads back to genes for quantification
        BWA_INDEX(ch_genes_fna)
        
        // Combine clean reads with indexed genes
        ch_mapping_input = ch_clean_reads
            .map { sample, r1, r2 -> tuple(sample, r1, r2) }
            .combine(BWA_INDEX.out.index.map { sample, idx -> tuple(sample, idx) }, by: 0)
        
        BWA_MEM(ch_mapping_input)
        SAMTOOLS_SORT(BWA_MEM.out.bam)
        SAMTOOLS_INDEX(SAMTOOLS_SORT.out.bam)
        
        // Create non-redundant gene set
        ch_all_genes = ch_genes_fna.map { sample, fna -> fna }.collect()
        CDHIT(ch_all_genes)
        ch_nr_genes = CDHIT.out.clustered
    }
    
    /*
    ================================================================================
       STEP 7: FUNCTIONAL ANNOTATION OF GENES
    ================================================================================
    */
    
    if (!params.skip_assembly && !params.skip_functional) {
        if (params.kegg_db) {
            KEGG_ANNOTATION(ch_genes_faa, params.kegg_db)
        }
        if (params.cazy_db) {
            CAZY_ANNOTATION(ch_genes_faa, params.cazy_db)
        }
    }
    
    /*
    ================================================================================
       STEP 8: CONTIG MAPPING FOR BINNING AND GROWTH RATES
    ================================================================================
    */
    
    if (!params.skip_assembly && (!params.skip_binning || !params.skip_growth_rates)) {
        // Build index for contigs
        BOWTIE2_BUILD(ch_filtered_contigs)
        
        // Map reads to contigs
        ch_bowtie_input = ch_clean_reads
            .map { sample, r1, r2 -> tuple(sample, r1, r2) }
            .combine(BOWTIE2_BUILD.out.index.map { sample, idx -> tuple(sample, idx) }, by: 0)
        
        BOWTIE2_ALIGN(ch_bowtie_input)
        ch_contig_bams = BOWTIE2_ALIGN.out.bam
        
        // Sort and index BAM files
        SAMTOOLS_SORT(ch_contig_bams)
        SAMTOOLS_INDEX(SAMTOOLS_SORT.out.bam)
        ch_sorted_bams = SAMTOOLS_SORT.out.bam
    }
    
    /*
    ================================================================================
       STEP 9: GENOME BINNING
    ================================================================================
    */
    
    if (!params.skip_assembly && !params.skip_binning) {
        // Collect all BAMs for each assembly
        ch_binning_input = ch_filtered_contigs
            .combine(ch_sorted_bams.groupTuple())
        
        def binning_tools = params.binning_tools.split(',')
        ch_all_bins = Channel.empty()
        
        // Run selected binning tools
        if ('metabat2' in binning_tools) {
            METABAT2(ch_binning_input)
            ch_all_bins = ch_all_bins.mix(METABAT2.out.bins)
        }
        if ('maxbin2' in binning_tools) {
            MAXBIN2(ch_binning_input)
            ch_all_bins = ch_all_bins.mix(MAXBIN2.out.bins)
        }
        if ('concoct' in binning_tools) {
            CONCOCT(ch_binning_input)
            ch_all_bins = ch_all_bins.mix(CONCOCT.out.bins)
        }
        
        // Integrate bins with DAS_Tool
        if (binning_tools.size() > 1) {
            ch_dastool_input = ch_all_bins
                .groupTuple()
                .combine(ch_filtered_contigs, by: 0)
            DASTOOL(ch_dastool_input)
            ch_final_bins = DASTOOL.out.bins
        } else {
            ch_final_bins = ch_all_bins
        }
        
        // Assess bin quality with CheckM
        if (params.checkm_db) {
            CHECKM(ch_final_bins, params.checkm_db)
            ch_checkm_results = CHECKM.out.results
        }
    }
    
    /*
    ================================================================================
       STEP 10: GROWTH RATE CALCULATION
    ================================================================================
    */
    
    if (!params.skip_assembly && !params.skip_growth_rates && !params.skip_binning) {
        // Prepare input for DEMIC (needs sorted SAM files)
        ch_demic_input = ch_sorted_bams
            .groupTuple()
            .combine(ch_final_bins, by: 0)
        
        DEMIC(ch_demic_input)
        ch_growth_rates = DEMIC.out.growth_rates
    }
    
    /*
    ================================================================================
       STEP 11: MULTIQC REPORT
    ================================================================================
    */
    
    if (!params.skip_qc) {
        ch_multiqc_files = Channel.empty()
        if (!params.skip_qc) {
            ch_multiqc_files = ch_multiqc_files.mix(ch_fastqc_results)
        }
        if (!params.skip_kneaddata) {
            ch_multiqc_files = ch_multiqc_files.mix(ch_kneaddata_logs.collect())
        }
        
        MULTIQC(ch_multiqc_files.collect())
    }
}

/*
========================================================================================
   WORKFLOW COMPLETION
========================================================================================
*/

workflow.onComplete {
    log.info """
    ================================================================
    Pipeline Completion Summary
    ================================================================
    Completed at : ${workflow.complete}
    Duration     : ${workflow.duration}
    Success      : ${workflow.success}
    Work Dir     : ${workflow.workDir}
    Exit status  : ${workflow.exitStatus}
    Error report : ${workflow.errorReport ?: 'None'}
    ================================================================
    """.stripIndent()
}

workflow.onError {
    log.error "Pipeline failed. See error report: ${workflow.errorReport}"
}
