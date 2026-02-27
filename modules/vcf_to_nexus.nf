process VCF_TO_NEXUS {
    label 'process_low'

    input:
    path vcf

    output:
    path 'alignment.nex', emit: nexus
    path 'versions.yml', emit: versions

    script:
    """
    vcf2nexus.py \\
        --input ${vcf} \\
        --output alignment.nex

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //g')
    END_VERSIONS
    """
}
