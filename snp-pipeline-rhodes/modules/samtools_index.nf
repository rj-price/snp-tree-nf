process SAMTOOLS_INDEX {
    tag "$meta.id"
    label 'process_low'
    publishDir "${params.outdir}/alignments", mode: 'copy'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.bai"), emit: bai

    script:
    """
    samtools index ${bam}
    """
}
