process ANGSD_PREPARE_BEAGLE {
    label 'process_high'
    publishDir "${params.outdir}/angsd", mode: 'copy'

    input:
    path bams
    path bais
    path reference
    path fai

    output:
    path "genotype_likelihoods.beagle.gz", emit: beagle
    path 'versions.yml', emit: versions

    script:
    """
    # Create BAM list file
    ls *.bam > bam.list
    
    angsd 
        -bam bam.list 
        -ref ${reference} 
        -nThreads ${task.cpus} 
        -uniqueOnly 1 
        -remove_bads 1 
        -only_proper_pairs 1 
        -GL 1 
        -doMajorMinor 1 
        -doMaf 1 
        -doGlf 2 
        -SNP_pval 1e-6 
        -out genotype_likelihoods

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        angsd: \$(angsd --version 2>&1 | head -n 1 | cut -d ' ' -f 2)
    END_VERSIONS
    """
}
