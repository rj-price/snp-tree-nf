#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SAMPLESHEET_CHECK } from './modules/samplesheet_check'
include { FASTQC as FASTQC_RAW } from './modules/fastqc'
include { FASTQC as FASTQC_TRIMMED } from './modules/fastqc'
include { TRIMMOMATIC } from './modules/trimmomatic'
include { BWA_INDEX } from './modules/bwa_index'
include { BWA_MEM } from './modules/bwa_mem'
include { SAMTOOLS_VIEW } from './modules/samtools_view'
include { SAMTOOLS_SORT } from './modules/samtools_sort'
include { SAMTOOLS_RMDUP } from './modules/samtools_rmdup'
include { SAMTOOLS_INDEX } from './modules/samtools_index'
include { SAMTOOLS_STATS } from './modules/samtools_stats'
include { SAMTOOLS_FAIDX } from './modules/samtools_faidx'
include { BCFTOOLS_MPILEUP } from './modules/bcftools_mpileup'
include { BCFTOOLS_FILTER } from './modules/bcftools_filter'
include { VCF_TO_PHYLIP } from './modules/vcf_to_phylip'
include { RAXML } from './modules/raxml'
include { VCF_TO_NEXUS } from './modules/vcf_to_nexus'
include { ANGSD_PREPARE_BEAGLE } from './modules/angsd_prepare_beagle'
include { NGSADMIX } from './modules/ngsadmix'
include { VCF_TO_MATRIX } from './modules/vcf_to_matrix'
include { ADE4_PCA } from './modules/ade4_pca'
include { CREATE_FASTA_LIST } from './modules/create_fasta_list'
include { SANS_SPLITS } from './modules/sans_splits'
include { MULTIQC } from './modules/multiqc'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {
    
    main:
    // Validate inputs
    if (!params.input) {
        error "Please provide a samplesheet using --input"
    }
    if (!params.fasta) {
        error "Please provide a reference genome using --fasta"
    }
    
    def ch_versions = channel.empty()
    
    //
    // SUBWORKFLOW: Validate and parse samplesheet
    //
    SAMPLESHEET_CHECK(
        file(params.input, checkIfExists: true)
    )
    ch_versions = ch_versions.mix(SAMPLESHEET_CHECK.out.versions)
    
    //
    // Create reads channel from samplesheet
    //
    SAMPLESHEET_CHECK.out.csv
        .splitCsv(header: true, sep: ',')
        .map { row ->
            def meta = [id: row.sample_id]
            def reads = [file(row.read1, checkIfExists: true), 
                        file(row.read2, checkIfExists: true)]
            return [meta, reads]
        }
        .set { ch_reads }
    
    //
    // MODULE: Quality control on raw reads
    //
    FASTQC_RAW(ch_reads)
    ch_versions = ch_versions.mix(FASTQC_RAW.out.versions.first())
    
    //
    // MODULE: Adapter trimming with Trimmomatic
    //
    def ch_adapters = params.adapters ? file(params.adapters, checkIfExists: true) : []
    
    TRIMMOMATIC(
        ch_reads,
        ch_adapters
    )
    ch_versions = ch_versions.mix(TRIMMOMATIC.out.versions.first())
    
    //
    // MODULE: Quality control on trimmed reads
    //
    FASTQC_TRIMMED(TRIMMOMATIC.out.trimmed_reads)
    ch_versions = ch_versions.mix(FASTQC_TRIMMED.out.versions.first())
    
    //
    // MODULE: Index reference genome with BWA
    //
    def ch_fasta = file(params.fasta, checkIfExists: true)
    
    BWA_INDEX(ch_fasta)
    ch_versions = ch_versions.mix(BWA_INDEX.out.versions)
    
    //
    // MODULE: Index reference genome with Samtools
    //
    SAMTOOLS_FAIDX(ch_fasta)
    ch_versions = ch_versions.mix(SAMTOOLS_FAIDX.out.versions)
    
    //
    // MODULE: Align reads with BWA-MEM
    //
    BWA_MEM(
        TRIMMOMATIC.out.trimmed_reads,
        BWA_INDEX.out.index
    )
    ch_versions = ch_versions.mix(BWA_MEM.out.versions.first())
    
    //
    // MODULE: Convert SAM to BAM
    //
    SAMTOOLS_VIEW(BWA_MEM.out.sam)
    ch_versions = ch_versions.mix(SAMTOOLS_VIEW.out.versions.first())
    
    //
    // MODULE: Sort BAM files
    //
    SAMTOOLS_SORT(SAMTOOLS_VIEW.out.bam)
    ch_versions = ch_versions.mix(SAMTOOLS_SORT.out.versions.first())

    //
    // MODULE: Remove duplicates
    //
    SAMTOOLS_RMDUP(SAMTOOLS_SORT.out.bam)
    ch_versions = ch_versions.mix(SAMTOOLS_RMDUP.out.versions.first())
    
    //
    // MODULE: Index BAM files
    //
    SAMTOOLS_INDEX(SAMTOOLS_RMDUP.out.bam)
    ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions.first())
    
    //
    // MODULE: Calculate alignment statistics
    //
    SAMTOOLS_STATS(SAMTOOLS_INDEX.out.bam_bai)
    ch_versions = ch_versions.mix(SAMTOOLS_STATS.out.versions.first())
    
    //
    // MODULE: Variant calling with BCFtools mpileup and call (JOINT CALLING)
    //
    BCFTOOLS_MPILEUP(
        SAMTOOLS_INDEX.out.bam_bai.map { _meta, bam -> bam }.collect(),
        SAMTOOLS_INDEX.out.bam_bai.map { _meta, _bam, bai -> bai }.collect(),
        SAMTOOLS_FAIDX.out.fasta_fai
    )
    ch_versions = ch_versions.mix(BCFTOOLS_MPILEUP.out.versions)
    
    //
    // MODULE: Filter variants (JOINT FILTERING)
    //
    BCFTOOLS_FILTER(BCFTOOLS_MPILEUP.out.vcf)
    ch_versions = ch_versions.mix(BCFTOOLS_FILTER.out.versions)
    
    //
    // MODULE: Convert VCF to PHYLIP format
    //
    VCF_TO_PHYLIP(BCFTOOLS_FILTER.out.vcf)
    ch_versions = ch_versions.mix(VCF_TO_PHYLIP.out.versions)
    
    //
    // MODULE: Phylogenetic tree construction with RAxML
    //
    RAXML(VCF_TO_PHYLIP.out.phylip)
    ch_versions = ch_versions.mix(RAXML.out.versions)
    
    //
    // MODULE: Convert VCF to NEXUS format
    //
    VCF_TO_NEXUS(BCFTOOLS_FILTER.out.vcf)
    ch_versions = ch_versions.mix(VCF_TO_NEXUS.out.versions)

    //
    // OPTIONAL: NGSadmix analysis
    //
    if (params.run_ngsadmix) {
        ANGSD_PREPARE_BEAGLE(
            SAMTOOLS_INDEX.out.bam_bai.map { _meta, bam, _bai -> bam }.collect(),
            SAMTOOLS_INDEX.out.bam_bai.map { _meta, _bam, bai -> bai }.collect(),
            ch_fasta,
            SAMTOOLS_FAIDX.out.fasta_fai.map { _fasta, fai -> fai }
        )
        ch_versions = ch_versions.mix(ANGSD_PREPARE_BEAGLE.out.versions)

        NGSADMIX(
            ANGSD_PREPARE_BEAGLE.out.beagle,
            params.ngsadmix_k,
            params.ngsadmix_runs
        )
        ch_versions = ch_versions.mix(NGSADMIX.out.versions)
    }

    //
    // OPTIONAL: PCA analysis
    //
    if (params.run_pca) {
        VCF_TO_MATRIX(BCFTOOLS_FILTER.out.vcf)
        ch_versions = ch_versions.mix(VCF_TO_MATRIX.out.versions)

        ADE4_PCA(
            VCF_TO_MATRIX.out.matrix,
            VCF_TO_MATRIX.out.samples
        )
        ch_versions = ch_versions.mix(ADE4_PCA.out.versions)
    }

    //
    // OPTIONAL: SANS splits analysis
    //
    if (params.run_sans) {
        if (!params.genome_list) {
            error "Please provide a genome list using --genome_list for SANS analysis"
        }
        SANS_SPLITS(
            file(params.genome_list, checkIfExists: true)
        )
        ch_versions = ch_versions.mix(SANS_SPLITS.out.versions)
    }
    
    //
    // MODULE: MultiQC aggregated report
    //
    def ch_multiqc_files = channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_RAW.out.zip.map { _meta, zip -> zip }.collect().ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_TRIMMED.out.zip.map { _meta, zip -> zip }.collect().ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(TRIMMOMATIC.out.log.map { _meta, log -> log }.collect().ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(SAMTOOLS_STATS.out.stats.map { _meta, stats -> stats }.collect().ifEmpty([]))
    
    MULTIQC(
        ch_multiqc_files.collect()
    )
    ch_versions = ch_versions.mix(MULTIQC.out.versions)
    
    //
    // Workflow completion handler
    //
    workflow.onComplete = {
        println "Pipeline completed at: ${workflow.complete}"
        println "Execution status: ${workflow.success ? 'OK' : 'failed'}"
        println "Duration: ${workflow.duration}"
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
