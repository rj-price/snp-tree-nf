#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/*
 * Variant Calling and Phylogenetic Analysis Pipeline
 * 
 * This pipeline performs:
 * 1. Quality control with FastQC
 * 2. Read alignment with BWA-MEM
 * 3. Variant calling with GATK HaplotypeCaller
 * 4. Variant filtering
 * 5. Phylogenetic tree construction with RAxML
 */

// ================================================================================
// Parameters
// ================================================================================

params.input = null                     // Input sample sheet (CSV: sample_id,read1,read2)
params.outdir = 'results'               // Output directory

// Reference genome files
params.reference = null                 // Reference genome FASTA (e.g., Af293)
params.reference_index = null           // BWA index files directory
params.reference_dict = null            // Reference dictionary file
params.reference_fai = null             // Reference FASTA index

// Repeat regions for exclusion
params.repeat_mask = null               // RepeatMasker BED file for exclusion

// Variant filtering parameters
params.min_depth = 10
params.min_mapping_quality = 40.0
params.min_qual_by_depth = 2.0
params.max_fisher_strand = 60.0
params.min_ab_hom = 0.9
params.min_genotype_quality = 50

// Phylogenetic analysis
params.raxml_model = 'GTRCAT'           // RAxML substitution model
params.raxml_bootstraps = 1000          // Number of bootstrap replicates

// Tool versions (for documentation)
params.fastqc_version = '0.11.5'
params.bwa_version = '0.7.8'
params.samtools_version = '1.3.1'
params.gatk_version = '4.0'
params.repeatmasker_version = '4.0.6'
params.raxml_version = '8.2.9'

// ================================================================================
// Include processes
// ================================================================================

include { FASTQC } from './modules/fastqc'
include { BWA_MEM } from './modules/bwa_mem'
include { SAMTOOLS_SORT } from './modules/samtools_sort'
include { SAMTOOLS_INDEX } from './modules/samtools_index'
include { GATK_HAPLOTYPECALLER } from './modules/gatk_haplotypecaller'
include { GATK_VARIANTFILTRATION } from './modules/gatk_variantfiltration'
include { CREATE_SNP_MATRIX } from './modules/create_snp_matrix'
include { RAXML_PHYLOGENY } from './modules/raxml_phylogeny'

// ================================================================================
// Main workflow
// ================================================================================

workflow {
    
    // Input validation
    if (!params.input) {
        error "Please provide an input sample sheet with --input"
    }
    
    if (!params.reference) {
        error "Please provide a reference genome with --reference"
    }
    
    // Parse input sample sheet
    // Expected format: sample_id,read1,read2
    Channel
        .fromPath(params.input)
        .splitCsv(header: true)
        .map { row -> 
            def meta = [id: row.sample_id]
            def reads = [file(row.read1), file(row.read2)]
            return [meta, reads]
        }
        .set { ch_reads }
    
    // Prepare reference files
    ch_reference = Channel.value(file(params.reference))
    ch_reference_fai = params.reference_fai ? 
        Channel.value(file(params.reference_fai)) : 
        Channel.empty()
    ch_reference_dict = params.reference_dict ? 
        Channel.value(file(params.reference_dict)) : 
        Channel.empty()
    ch_repeat_mask = params.repeat_mask ? 
        Channel.value(file(params.repeat_mask)) : 
        Channel.empty()
    
    // Quality control
    FASTQC(ch_reads)
    
    // Alignment
    BWA_MEM(
        ch_reads,
        ch_reference
    )
    
    // Sort BAM files
    SAMTOOLS_SORT(BWA_MEM.out.bam)
    
    // Index BAM files
    SAMTOOLS_INDEX(SAMTOOLS_SORT.out.bam)
    
    // Combine BAM and BAI for variant calling
    ch_bam_bai = SAMTOOLS_SORT.out.bam
        .join(SAMTOOLS_INDEX.out.bai, by: 0)
    
    // Variant calling
    GATK_HAPLOTYPECALLER(
        ch_bam_bai,
        ch_reference,
        ch_reference_fai,
        ch_reference_dict,
        ch_repeat_mask
    )
    
    // Variant filtering
    GATK_VARIANTFILTRATION(
        GATK_HAPLOTYPECALLER.out.vcf,
        ch_reference,
        ch_reference_fai,
        ch_reference_dict
    )
    
    // Collect all VCF files for phylogenetic analysis
    ch_all_vcfs = GATK_VARIANTFILTRATION.out.vcf.collect()
    
    // Create SNP presence/absence matrix
    CREATE_SNP_MATRIX(
        ch_all_vcfs,
        ch_reference
    )
    
    // Build phylogenetic tree
    RAXML_PHYLOGENY(CREATE_SNP_MATRIX.out.phylip)
    
    // ================================================================================
    // Workflow completion handler
    // ================================================================================
    
    workflow.onComplete {
        log.info """
        Pipeline execution summary
        ---------------------------
        Completed at: ${workflow.complete}
        Duration    : ${workflow.duration}
        Success     : ${workflow.success}
        workDir     : ${workflow.workDir}
        Results     : ${params.outdir}
        exit status : ${workflow.exitStatus}
        """
    }
}
