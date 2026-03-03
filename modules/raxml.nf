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
    # RAxML requires at least 4 taxa
    NUM_TAXA=\$(head -n 1 ${phylip} | awk '{print \$1}')
    
    if [ "\$NUM_TAXA" -ge 4 ]; then
        raxmlHPC-PTHREADS-SSE3 \\
            -T ${task.cpus} \\
            -m GTRGAMMA \\
            -p 12345 \\
            -s $phylip \\
            -n tree \\
            -# 100
    else
        echo "WARNING: Only \$NUM_TAXA species found in alignment. RAxML requires at least 4. Skipping tree construction."
        touch RAxML_bestTree.tree
        touch RAxML_info.tree
        touch RAxML_log.tree
        touch RAxML_result.tree
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        raxml: \$(raxmlHPC-PTHREADS-SSE3 -version | head -n1 | sed 's/.*version //' | sed 's/ .*//')
    END_VERSIONS
    """
}
