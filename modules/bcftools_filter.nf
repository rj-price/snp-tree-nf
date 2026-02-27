process BCFTOOLS_FILTER {
    label 'process_medium'

    input:
    path vcf

    output:
    path 'joint_calls.filtered.vcf.gz', emit: vcf
    path 'versions.yml', emit: versions

    script:
    """
    bcftools view \\
        --types snps \\
        $vcf \\
        | bcftools filter \\
            --include 'QUAL>=20 && INFO/DP>=10 && INFO/MQ>=30' \\
            --output-type z \\
            --output joint_calls.filtered.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version | head -n1 | sed 's/bcftools //')
    END_VERSIONS
    """
}
