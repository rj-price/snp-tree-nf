process CREATE_FASTA_LIST {
    label 'process_single'

    input:
    path fastas

    output:
    path "fasta_list.txt", emit: list

    script:
    """
    ls *.fasta > fasta_list.txt
    """
}
