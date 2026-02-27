process BCFTOOLS_MPILEUP {
    label 'process_high'

    input:
    path bams
    path bais
    tuple path(fasta), path(fai)

    output:
    path 'joint_calls.vcf.gz', emit: vcf
    path 'versions.yml', emit: versions

    script:
    """
    bcftools mpileup \\
        --fasta-ref $fasta \\
        --output-type u \\
        $bams \\
        | bcftools call \\
            --multiallelic-caller \\
            --variants-only \\
            --output-type z \\
            --output joint_calls.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version | head -n1 | sed 's/bcftools //')
    END_VERSIONS
    """
}
