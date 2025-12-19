process VCF_TO_PHYLIP {
    tag "all_samples"
    label 'process_low'

    input:
    path vcfs

    output:
    path 'alignment.phy', emit: phylip
    path 'versions.yml', emit: versions

    script:
    """
    vcf2phylip.py \\
        --input *.filtered.vcf.gz \\
        --output alignment.phy

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
