process PLOT_PCANGSD {
    label 'process_low'
    publishDir "${params.outdir}/pcangsd/plots", mode: 'copy'

    input:
    path admix
    path cov
    path sample_names

    output:
    path "*.admixture.png", emit: admix_plot
    path "*.pca.png",       emit: pca_plot
    path 'versions.yml',    emit: versions

    script:
    """
    #!/usr/bin/env python3
    import numpy as np
    import matplotlib.pyplot as plt
    import pandas as pd

    # Read sample names
    with open("${sample_names}", 'r') as f:
        samples = [line.strip() for line in f]

    # Plot Admixture
    q_file = "${admix}"
    q = np.loadtxt(q_file)
    
    plt.figure(figsize=(12, 6))
    bottom = np.zeros(len(samples))
    for i in range(q.shape[1]):
        plt.bar(samples, q[:, i], bottom=bottom, label=f'Cluster {i+1}')
        bottom += q[:, i]
    
    plt.title(f'Admixture Proportions (K={q.shape[1]})')
    plt.ylabel('Proportion')
    plt.xticks(rotation=45, ha='right')
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.tight_layout()
    plt.savefig('pcangsd.admixture.png', dpi=300)
    plt.close()

    # Plot PCA from covariance matrix
    cov_file = "${cov}"
    c = np.genfromtxt(cov_file)
    
    # Eigen decomposition
    eig_vals, eig_vecs = np.linalg.eigh(c)
    
    # Sort eigenvalues and eigenvectors in descending order
    idx = eig_vals.argsort()[::-1]
    eig_vals = eig_vals[idx]
    eig_vecs = eig_vecs[:, idx]
    
    # Calculate variance explained
    var_exp = eig_vals / np.sum(eig_vals) * 100
    
    plt.figure(figsize=(10, 8))
    plt.scatter(eig_vecs[:, 0], eig_vecs[:, 1], alpha=0.7)
    
    for i, txt in enumerate(samples):
        plt.annotate(txt, (eig_vecs[i, 0], eig_vecs[i, 1]), fontsize=8)
        
    plt.title('PCA from PCAngsd Covariance Matrix')
    plt.xlabel(f'PC1 ({var_exp[0]:.2f}%)')
    plt.ylabel(f'PC2 ({var_exp[1]:.2f}%)')
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig('pcangsd.pca.png', dpi=300)
    plt.close()

    # Write versions
    with open("versions.yml", "w") as f:
        f.write('"${task.process}":\\n')
        f.write(f'    python: {np.__name__} {np.__version__}\\n')
        f.write(f'    matplotlib: {plt.matplotlib.__version__}\\n')
    """
}
