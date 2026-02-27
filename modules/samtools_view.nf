process SAMTOOLS_VIEW {
    tag "$meta.id"
    label 'process_medium'

    input:
    tuple val(meta), path(sam)

    output:
    tuple val(meta), path('*.bam'), emit: bam
    path 'versions.yml', emit: versions

    script:
    def prefix = "${meta.id}"
    """
    samtools view \\
        -@ ${task.cpus} \\
        -b \\
        -h \\
        -o ${prefix}.bam \\
        $sam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -n1 | sed 's/samtools //')
    END_VERSIONS
    """
}
