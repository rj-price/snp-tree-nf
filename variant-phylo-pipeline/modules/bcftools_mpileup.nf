process BCFTOOLS_MPILEUP {
    tag "$meta.id"
    label 'process_medium'

    input:
    tuple val(meta), path(bam), path(bai)
    tuple path(fasta), path(fai)

    output:
    tuple val(meta), path('*.vcf.gz'), emit: vcf
    path 'versions.yml', emit: versions

    script:
    def prefix = "${meta.id}"
    """
    bcftools mpileup \\
        --fasta-ref $fasta \\
        --output-type u \\
        $bam \\
        | bcftools call \\
            --multiallelic-caller \\
            --variants-only \\
            --output-type z \\
            --output ${prefix}.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version | head -n1 | sed 's/bcftools //')
    END_VERSIONS
    """
}
