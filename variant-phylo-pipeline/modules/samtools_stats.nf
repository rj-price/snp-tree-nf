process SAMTOOLS_STATS {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path('*.stats'), emit: stats
    path 'versions.yml', emit: versions

    script:
    def prefix = "${meta.id}"
    """
    samtools stats \\
        $bam \\
        > ${prefix}.stats

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -n1 | sed 's/samtools //')
    END_VERSIONS
    """
}
