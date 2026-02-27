process NGSADMIX {
    tag "K=${k}"
    label 'process_medium'
    publishDir "${params.outdir}/ngsadmix/K${k}", mode: 'copy'

    input:
    path beagle
    val k
    val run_id

    output:
    tuple val(k), val(run_id), path("*.qopt"), path("*.fopt.gz"), path("*.log"), emit: results
    path 'versions.yml', emit: versions

    script:
    """
    NGSadmix 
        -likes ${beagle} 
        -K ${k} 
        -minMaf 0.01 
        -seed ${run_id} 
        -o K${k}_run${run_id}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        NGSadmix: "v32"
    END_VERSIONS
    """
}
