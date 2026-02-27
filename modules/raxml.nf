process RAXML {
    tag "phylogenetic_tree"
    label 'process_high'

    input:
    path phylip

    output:
    path 'RAxML_*', emit: results
    path 'RAxML_bestTree.*', emit: best_tree
    path 'versions.yml', emit: versions

    script:
    """
    raxmlHPC-PTHREADS-SSE3 \\
        -T ${task.cpus} \\
        -m GTRGAMMA \\
        -p 12345 \\
        -s $phylip \\
        -n tree \\
        -# 100

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        raxml: \$(raxmlHPC-PTHREADS-SSE3 -version | head -n1 | sed 's/.*version //' | sed 's/ .*//')
    END_VERSIONS
    """
}
