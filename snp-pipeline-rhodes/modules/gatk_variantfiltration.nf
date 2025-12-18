process GATK_VARIANTFILTRATION {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}/variants/filtered", mode: 'copy'

    input:
    tuple val(meta), path(vcf), path(vcf_tbi)
    path reference
    path reference_fai
    path reference_dict

    output:
    tuple val(meta), path("*.filtered.vcf.gz"), emit: vcf

    script:
    def prefix = "${meta.id}"
    """
    # First apply GATK VariantFiltration for standard filters
    gatk VariantFiltration \\
        --java-options "-Xmx${task.memory.toGiga()}g" \\
        -R ${reference} \\
        -V ${vcf} \\
        -O ${prefix}.filtered.temp.vcf.gz \\
        --filter-name "LowDepth" \\
        --filter-expression "DP < ${params.min_depth}" \\
        --filter-name "LowMappingQuality" \\
        --filter-expression "MQ < ${params.min_mapping_quality}" \\
        --filter-name "LowQualByDepth" \\
        --filter-expression "QD < ${params.min_qual_by_depth}" \\
        --filter-name "StrandBias" \\
        --filter-expression "FS > ${params.max_fisher_strand}"
    
    # Extract variants that PASS and apply additional custom filters
    bcftools view \\
        -f PASS \\
        ${prefix}.filtered.temp.vcf.gz \\
        | bcftools view \\
            -i "FORMAT/GQ >= ${params.min_genotype_quality}" \\
            -O z \\
            -o ${prefix}.filtered.vcf.gz
    
    # Index the final VCF
    bcftools index -t ${prefix}.filtered.vcf.gz
    
    # Clean up temporary file
    rm ${prefix}.filtered.temp.vcf.gz*
    """
}
