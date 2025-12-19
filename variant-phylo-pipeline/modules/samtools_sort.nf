process SAMTOOLS_SORT {
    tag "$meta.id"
    label 'process_medium'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path('*.sorted.bam'), emit: bam
    path 'versions.yml', emit: versions

    script:
    def prefix = "${meta.id}"
    """
    samtools sort \\
        -@ ${task.cpus} \\
        -o ${prefix}.sorted.bam \\
        $bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -n1 | sed 's/samtools //')
    END_VERSIONS
    """
}
