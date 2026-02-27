process SANS_SPLITS {
    label 'process_high'
    publishDir "${params.outdir}/phylogenetics", mode: 'copy'

    input:
    path fasta_list

    output:
    path "*.splits", emit: splits
    path "*.nexus",  emit: nexus
    path 'versions.yml', emit: versions

    script:
    def prefix = fasta_list.baseName
    """
    SANS 
        -T ${task.cpus} 
        -v 
        -i ${fasta_list} 
        -o ${prefix}.splits 
        -X ${prefix}.nexus 
        -t 10n 
        -f weakly

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        SANS: \$(SANS --version 2>&1 | head -n 1 | sed 's/SANS //')
    END_VERSIONS
    """
}
