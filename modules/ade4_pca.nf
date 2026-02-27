process ADE4_PCA {
    label 'process_medium'
    publishDir "${params.outdir}/pca", mode: 'copy'

    input:
    path matrix
    path sample_names

    output:
    path "pca_results.rds", emit: pca_object
    path "pca_summary.txt", emit: summary
    path "pca_plot.pdf", emit: plot
    path "pca_coordinates.txt", emit: coordinates
    path 'versions.yml', emit: versions

    script:
    def center = params.pca_center ? "TRUE" : "FALSE"
    def scale = params.pca_scale ? "TRUE" : "FALSE"
    """
    #!/usr/bin/env Rscript
    
    # Load required library
    library(ade4)
    
    # Read SNP matrix
    snp_data <- read.table("${matrix}", header = TRUE, row.names = 1, sep = "	", 
                          na.strings = "NA", check.names = FALSE)
    
    # Convert to numeric matrix
    snp_matrix <- as.matrix(snp_data)
    mode(snp_matrix) <- "numeric"
    
    # Remove SNPs with too much missing data (>50%)
    missing_per_snp <- apply(snp_matrix, 2, function(x) sum(is.na(x)) / length(x))
    snp_matrix <- snp_matrix[, missing_per_snp < 0.5]
    
    # Impute missing values with column means
    for (i in 1:ncol(snp_matrix)) {
        col_mean <- mean(snp_matrix[, i], na.rm = TRUE)
        snp_matrix[is.na(snp_matrix[, i]), i] <- col_mean
    }
    
    # Perform PCA using ade4 package
    pca_result <- dudi.pca(snp_matrix, center = ${center}, scale = ${scale}, 
                          scannf = FALSE, nf = 5)
    
    # Save PCA object
    saveRDS(pca_result, "pca_results.rds")
    
    # Write summary
    sink("pca_summary.txt")
    cat("PCA Analysis Summary
")
    cat("====================

")
    cat("Settings:
")
    cat("  - Centered: ${center}
")
    cat("  - Scaled: ${scale}

")
    cat("Number of samples:", nrow(snp_matrix), "
")
    cat("Number of SNPs:", ncol(snp_matrix), "

")
    cat("Eigenvalues:
")
    print(pca_result\$eig)
    cat("

Variance explained by each PC:
")
    variance_explained <- pca_result\$eig / sum(pca_result\$eig) * 100
    for (i in 1:min(5, length(variance_explained))) {
        cat(sprintf("PC%d: %.2f%%
", i, variance_explained[i]))
    }
    sink()
    
    # Create PCA plot
    pdf("pca_plot.pdf", width = 10, height = 8)
    
    # Plot 1: PC1 vs PC2
    s.label(pca_result\$li, xax = 1, yax = 2, 
            main = "PCA - PC1 vs PC2")
    
    # Plot 2: Eigenvalue barplot
    barplot(pca_result\$eig[1:min(10, length(pca_result\$eig))], 
            main = "Scree Plot", 
            xlab = "Principal Component", 
            ylab = "Eigenvalue",
            names.arg = 1:min(10, length(pca_result\$eig)))
    
    # Plot 3: PC2 vs PC3
    if (ncol(pca_result\$li) >= 3) {
        s.label(pca_result\$li, xax = 2, yax = 3, 
                main = "PCA - PC2 vs PC3")
    }
    
    dev.off()
    
    # Write coordinates
    write.table(pca_result\$li, "pca_coordinates.txt", 
                quote = FALSE, sep = "	", col.names = NA)

    # Write versions
    r_version <- paste0(R.version\$major, ".", R.version\$minor)
    ade4_version <- as.character(packageVersion("ade4"))
    
    sink("versions.yml")
    cat(paste0('"${task.process}":
'))
    cat(paste0('    R: ', r_version, '
'))
    cat(paste0('    ade4: ', ade4_version, '
'))
    sink()
    """
}
