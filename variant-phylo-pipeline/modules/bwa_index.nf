process BWA_INDEX {
    tag "$fasta"
    label 'process_high'

    input:
    path fasta

    output:
    tuple path(fasta), path('*.{amb,ann,bwt,pac,sa}'), emit: index
    path 'versions.yml', emit: versions

    script:
    """
    bwa index $fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwa: \$(bwa 2>&1 | grep -e 'Version' | sed 's/Version: //')
    END_VERSIONS
    """
}
