process BWA_MEM {
    tag "$meta.id"
    label 'process_high'

    input:
    tuple val(meta), path(reads)
    path reference

    output:
    tuple val(meta), path("*.bam"), emit: bam

    script:
    def prefix = "${meta.id}"
    def read_group = "@RG\\tID:${meta.id}\\tSM:${meta.id}\\tPL:ILLUMINA"
    """
    bwa mem \\
        -t ${task.cpus} \\
        -R "${read_group}" \\
        ${reference} \\
        ${reads[0]} \\
        ${reads[1]} \\
        | samtools view -b -h -o ${prefix}.bam -
    """
}
