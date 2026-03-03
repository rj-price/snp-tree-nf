process MULTIQC {
    label 'process_low'

    input:
    path multiqc_files

    output:
    path 'multiqc_report.html', emit: report
    path 'multiqc_report_data', emit: data
    path 'versions.yml', emit: versions

    script:
    """
    multiqc \\
        --force \\
        --title "Variant Calling Pipeline Report" \\
        --filename "multiqc_report.html" \\
        .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$(multiqc --version | sed 's/multiqc, version //')
    END_VERSIONS
    """
}
