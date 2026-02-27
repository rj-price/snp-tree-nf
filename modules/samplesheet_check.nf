process SAMPLESHEET_CHECK {
    tag "$samplesheet"
    label 'process_single'

    input:
    path samplesheet

    output:
    path '*.csv', emit: csv
    path 'versions.yml', emit: versions

    script:
    """
    check_samplesheet.py \\
        $samplesheet \\
        samplesheet.valid.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
