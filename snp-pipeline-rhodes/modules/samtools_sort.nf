process SAMTOOLS_SORT {
    tag "$meta.id"
    label 'process_medium'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.sorted.bam"), emit: bam

    script:
    def prefix = "${meta.id}"
    """
    samtools sort \\
        -@ ${task.cpus} \\
        -o ${prefix}.sorted.bam \\
        ${bam}
    """
}
