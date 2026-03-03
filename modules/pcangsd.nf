process PCANGSD {
    label 'process_medium'
    publishDir "${params.outdir}/pcangsd", mode: 'copy'

    input:
    path beagle

    output:
    path "*.admix.*.Q",   emit: admix
    path "*.admix.*.P",   emit: ancestral_freqs
    path "*.cov",         emit: cov
    path "*.args",        emit: args, optional: true
    path 'versions.yml',  emit: versions

    script:
    """
    pcangsd \\
        --beagle ${beagle} \\
        --admix \\
        --out results \\
        --threads ${task.cpus}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pcangsd: \$(pcangsd --version 2>&1 | grep "PCAngsd" | sed 's/PCAngsd v//')
    END_VERSIONS
    """
}
