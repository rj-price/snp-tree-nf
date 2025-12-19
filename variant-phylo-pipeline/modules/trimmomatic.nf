process TRIMMOMATIC {
    tag "$meta.id"
    label 'process_high'

    input:
    tuple val(meta), path(reads)
    path adapters

    output:
    tuple val(meta), path('*_paired_*.fastq.gz'), emit: trimmed_reads
    tuple val(meta), path('*_unpaired_*.fastq.gz'), emit: unpaired_reads
    tuple val(meta), path('*.log'), emit: log
    path 'versions.yml', emit: versions

    script:
    def prefix = "${meta.id}"
    def adapter_file = adapters ?: 'NO_FILE'
    def illuminaclip = adapter_file != 'NO_FILE' ? "ILLUMINACLIP:${adapter_file}:2:30:10" : ""
    """
    trimmomatic PE \\
        -threads ${task.cpus} \\
        -phred33 \\
        ${reads[0]} ${reads[1]} \\
        ${prefix}_paired_1.fastq.gz ${prefix}_unpaired_1.fastq.gz \\
        ${prefix}_paired_2.fastq.gz ${prefix}_unpaired_2.fastq.gz \\
        ${illuminaclip} \\
        SLIDINGWINDOW:4:20 \\
        MINLEN:36 \\
        HEADCROP:10 \\
        2> ${prefix}.trimmomatic.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trimmomatic: \$(trimmomatic -version 2>&1 | sed 's/^.*Trimmomatic-//; s/ .*\$//')
    END_VERSIONS
    """
}
