process VCF_TO_PHYLIP {
    label 'process_low'

    input:
    path vcf

    output:
    path 'alignment.phy', emit: phylip
    path 'versions.yml', emit: versions

    script:
    """
    vcf2phylip.py \\
        --input ${vcf} \\
        --output alignment.phy

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //g')
    END_VERSIONS
    """
}
