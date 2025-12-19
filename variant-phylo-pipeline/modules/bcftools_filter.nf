process BCFTOOLS_FILTER {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(vcf)

    output:
    tuple val(meta), path('*.filtered.vcf.gz'), emit: vcf
    path 'versions.yml', emit: versions

    script:
    def prefix = "${meta.id}"
    """
    bcftools view \\
        --types snps \\
        $vcf \\
        | bcftools filter \\
            --include 'QUAL>=20 && INFO/DP>=10 && INFO/MQ>=30' \\
            --output-type z \\
            --output ${prefix}.filtered.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version | head -n1 | sed 's/bcftools //')
    END_VERSIONS
    """
}
