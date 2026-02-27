process SAMTOOLS_INDEX {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path(bam), path('*.bai'), emit: bam_bai
    path 'versions.yml', emit: versions

    script:
    """
    samtools index \\
        -@ ${task.cpus} \\
        $bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -n1 | sed 's/samtools //')
    END_VERSIONS
    """
}
