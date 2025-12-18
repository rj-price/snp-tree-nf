process GATK_HAPLOTYPECALLER {
    tag "$meta.id"
    label 'process_high'
    publishDir "${params.outdir}/variants/raw", mode: 'copy'

    input:
    tuple val(meta), path(bam), path(bai)
    path reference
    path reference_fai
    path reference_dict
    path repeat_mask

    output:
    tuple val(meta), path("*.vcf.gz"), path("*.vcf.gz.tbi"), emit: vcf

    script:
    def prefix = "${meta.id}"
    def exclude_intervals = repeat_mask.name != 'NO_FILE' ? "-XL ${repeat_mask}" : ""
    """
    gatk HaplotypeCaller \\
        --java-options "-Xmx${task.memory.toGiga()}g" \\
        -R ${reference} \\
        -I ${bam} \\
        -O ${prefix}.raw.vcf.gz \\
        ${exclude_intervals}
    """
}
