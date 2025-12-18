process FASTQC {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}/fastqc", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.zip"),  emit: zip

    script:
    """
    fastqc \\
        --quiet \\
        --threads ${task.cpus} \\
        ${reads}
    """
}
