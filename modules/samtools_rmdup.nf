process SAMTOOLS_RMDUP {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}/samtools", mode: 'copy'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${meta.id}.dedup.bam"), emit: bam
    path 'versions.yml', emit: versions

    script:
    """
    samtools rmdup \\
        ${bam} \\
        ${meta.id}.dedup.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -n1 | sed 's/samtools //')
    END_VERSIONS
    """
}
