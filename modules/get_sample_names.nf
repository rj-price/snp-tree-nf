process GET_SAMPLE_NAMES {
    label 'process_low'

    input:
    val sample_ids

    output:
    path "sample_names.txt", emit: samples

    script:
    def samples = sample_ids.join("\n")
    """
    echo "${samples}" > sample_names.txt
    """
}
