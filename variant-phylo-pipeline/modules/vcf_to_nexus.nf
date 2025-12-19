process VCF_TO_NEXUS {
    tag "all_samples"
    label 'process_low'

    input:
    path vcfs

    output:
    path 'alignment.nex', emit: nexus
    path 'versions.yml', emit: versions

    script:
    """
    vcf2nexus.py \\
        --input *.filtered.vcf.gz \\
        --output alignment.nex

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
