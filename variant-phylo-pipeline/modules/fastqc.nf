process FASTQC {
    tag "$meta.id"
    label 'process_medium'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*.html'), emit: html
    tuple val(meta), path('*.zip'), emit: zip
    path 'versions.yml', emit: versions

    script:
    """
    fastqc \\
        --quiet \\
        --threads ${task.cpus} \\
        $reads

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: \$(fastqc --version | sed 's/FastQC v//g')
    END_VERSIONS
    """
}
