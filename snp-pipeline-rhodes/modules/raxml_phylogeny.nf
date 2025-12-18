process RAXML_PHYLOGENY {
    label 'process_high'
    publishDir "${params.outdir}/phylogenetics", mode: 'copy'

    input:
    path phylip

    output:
    path "RAxML_*", emit: all_outputs
    path "RAxML_bestTree.*", emit: best_tree
    path "RAxML_bipartitions.*", emit: bipartitions

    script:
    def model = params.raxml_model
    def bootstraps = params.raxml_bootstraps
    """
    # Run RAxML with rapid bootstrap analysis
    raxmlHPC \\
        -f a \\
        -x 12345 \\
        -p 12345 \\
        -# ${bootstraps} \\
        -m ${model} \\
        -s ${phylip} \\
        -n phylogeny \\
        -T ${task.cpus}
    """
}
