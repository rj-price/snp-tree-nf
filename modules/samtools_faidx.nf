process SAMTOOLS_FAIDX {
    tag "$fasta"
    label 'process_low'

    input:
    path fasta

    output:
    tuple path(fasta), path('*.fai'), emit: fasta_fai
    path 'versions.yml', emit: versions

    script:
    """
    samtools faidx $fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -n1 | sed 's/samtools //')
    END_VERSIONS
    """
}
