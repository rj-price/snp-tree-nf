process VCF_TO_MATRIX {
    label 'process_low'
    publishDir "${params.outdir}/pca", mode: 'copy'

    input:
    path vcf

    output:
    path "snp_matrix.txt", emit: matrix
    path "sample_names.txt", emit: samples
    path 'versions.yml', emit: versions

    script:
    """
    vcf2matrix.py \\
        --vcf ${vcf} \\
        --matrix snp_matrix.txt \\
        --samples sample_names.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //')
    END_VERSIONS
    """
}
