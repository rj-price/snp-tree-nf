process BWA_MEM {
    tag "$meta.id"
    label 'process_high'

    input:
    tuple val(meta), path(reads)
    tuple path(fasta), path(index)

    output:
    tuple val(meta), path('*.sam'), emit: sam
    path 'versions.yml', emit: versions

    script:
    def prefix = "${meta.id}"
    def read_group = "@RG\\tID:${meta.id}\\tSM:${meta.id}\\tPL:ILLUMINA\\tLB:${meta.id}"
    """
    bwa mem \\
        -t ${task.cpus} \\
        -R '${read_group}' \\
        $fasta \\
        ${reads[0]} \\
        ${reads[1]} \\
        > ${prefix}.sam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwa: \$(bwa 2>&1 | grep -e 'Version' | sed 's/Version: //')
    END_VERSIONS
    """
}
