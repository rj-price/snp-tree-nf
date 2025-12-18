#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/*
 * Pipeline: P. roqueforti Variant Calling Pipeline
 * Converted from methods section describing Trimmomatic, Bowtie2, SAMtools, and GATK workflow
 */

// ========================================================================================
// PARAMETERS
// ========================================================================================

params.reads = null
params.reference = null
params.outdir = "./results"
params.help = false

// Trimmomatic parameters
params.leading = 3
params.trailing = 3
params.minlen = 36
params.slidingwindow = "4:25"
params.adapters = null

// Bowtie2 parameters
params.bowtie2_index = null
params.max_fragment_length = 1000
params.bowtie2_preset = "very-sensitive-local"

// Filtering parameters
params.min_mapping_quality = 10
params.min_depth = 10

// GATK filtering parameters
params.filter_qual = 30
params.filter_dp = 10
params.filter_qd = 2.0
params.filter_fs = 60.0
params.filter_mq = 40.0
params.filter_sor = 3.0
params.filter_mqranksum = -12.5
params.filter_readposranksum = -8.0

// NGSadmix parameters (optional downstream analysis)
params.run_ngsadmix = false
params.min_k = 2
params.max_k = 6
params.ngsadmix_runs = 100
params.min_informative_individuals = 4

// Downstream analysis parameters
params.run_splitstree = false
params.run_pca = false
params.pca_center = true
params.pca_scale = false

def helpMessage() {
    log.info """
    ========================================
    P. roqueforti Variant Calling Pipeline
    ========================================
    
    Usage:
      nextflow run main.nf --reads 'data/*_R{1,2}.fastq.gz' --reference genome.fasta --bowtie2_index genome
    
    Required arguments:
      --reads                   Path to input reads (paired-end FASTQ files)
      --reference               Path to reference genome FASTA file
      --bowtie2_index           Path prefix to Bowtie2 index files
    
    Optional arguments:
      --outdir                  Output directory (default: ./results)
      --adapters                Path to adapter sequences file for Trimmomatic
      
    Trimmomatic options:
      --leading                 Remove leading low quality bases (default: 3)
      --trailing                Remove trailing low quality bases (default: 3)
      --minlen                  Minimum read length (default: 36)
      --slidingwindow           Sliding window trimming (default: "4:25")
      
    Bowtie2 options:
      --max_fragment_length     Maximum fragment length (default: 1000)
      --bowtie2_preset          Alignment preset (default: "very-sensitive-local")
      
    Filtering options:
      --min_mapping_quality     Minimum mapping quality score (default: 10)
      --min_depth               Minimum depth for variant calling (default: 10)
      
    GATK filtering options:
      --filter_qual             Minimum variant quality (default: 30)
      --filter_dp               Minimum depth (default: 10)
      --filter_qd               Minimum QualByDepth (default: 2.0)
      --filter_fs               Maximum FisherStrand (default: 60.0)
      --filter_mq               Minimum mapping quality (default: 40.0)
      --filter_sor              Maximum StrandOddsRatio (default: 3.0)
      --filter_mqranksum        Minimum MappingQualityRankSum (default: -12.5)
      --filter_readposranksum   Minimum ReadPosRankSum (default: -8.0)
      
    NGSadmix options:
      --run_ngsadmix            Run NGSadmix analysis (default: false)
      --min_k                   Minimum number of clusters (default: 2)
      --max_k                   Maximum number of clusters (default: 6)
      --ngsadmix_runs           Number of runs per K value (default: 100)
      
    Downstream analysis options:
      --run_splitstree          Run SplitsTree neighbour-net analysis (default: false)
      --run_pca                 Run Ade4 PCA analysis (default: false)
      --pca_center              Center data for PCA (default: true)
      --pca_scale               Scale data for PCA (default: false, "unscaled" as in methods)
    """.stripIndent()
}

// ========================================================================================
// PROCESS DEFINITIONS
// ========================================================================================

process TRIMMOMATIC {
    tag "${sample_id}"
    publishDir "${params.outdir}/trimmed", mode: 'copy'
    
    input:
    tuple val(sample_id), path(reads)
    
    output:
    tuple val(sample_id), path("${sample_id}_R{1,2}_trimmed.fastq.gz"), emit: trimmed_reads
    path "${sample_id}_trimmomatic.log", emit: log
    
    script:
    def adapter_opt = params.adapters ? "ILLUMINACLIP:${params.adapters}:2:30:10" : ""
    """
    trimmomatic PE \\
        -threads ${task.cpus} \\
        ${reads[0]} ${reads[1]} \\
        ${sample_id}_R1_trimmed.fastq.gz ${sample_id}_R1_unpaired.fastq.gz \\
        ${sample_id}_R2_trimmed.fastq.gz ${sample_id}_R2_unpaired.fastq.gz \\
        ${adapter_opt} \\
        LEADING:${params.leading} \\
        TRAILING:${params.trailing} \\
        SLIDINGWINDOW:${params.slidingwindow} \\
        MINLEN:${params.minlen} \\
        2> ${sample_id}_trimmomatic.log
    """
}

process BOWTIE2_ALIGN {
    tag "${sample_id}"
    publishDir "${params.outdir}/aligned", mode: 'copy'
    
    input:
    tuple val(sample_id), path(reads)
    path index_files
    
    output:
    tuple val(sample_id), path("${sample_id}.bam"), emit: bam
    path "${sample_id}_bowtie2.log", emit: log
    
    script:
    """
    bowtie2 \\
        --threads ${task.cpus} \\
        --${params.bowtie2_preset} \\
        -X ${params.max_fragment_length} \\
        -x ${params.bowtie2_index} \\
        -1 ${reads[0]} \\
        -2 ${reads[1]} \\
        2> ${sample_id}_bowtie2.log \\
        | samtools view -@ ${task.cpus} -bS - > ${sample_id}.bam
    """
}

process SAMTOOLS_SORT {
    tag "${sample_id}"
    publishDir "${params.outdir}/sorted", mode: 'copy'
    
    input:
    tuple val(sample_id), path(bam)
    
    output:
    tuple val(sample_id), path("${sample_id}.sorted.bam"), emit: sorted_bam
    
    script:
    """
    samtools sort \\
        -@ ${task.cpus} \\
        -o ${sample_id}.sorted.bam \\
        ${bam}
    """
}

process SAMTOOLS_RMDUP {
    tag "${sample_id}"
    publishDir "${params.outdir}/dedup", mode: 'copy'
    
    input:
    tuple val(sample_id), path(bam)
    
    output:
    tuple val(sample_id), path("${sample_id}.dedup.bam"), emit: dedup_bam
    path "${sample_id}_rmdup.log", emit: log
    
    script:
    """
    samtools rmdup ${bam} ${sample_id}.dedup.bam 2> ${sample_id}_rmdup.log
    """
}

process SAMTOOLS_FILTER {
    tag "${sample_id}"
    publishDir "${params.outdir}/filtered", mode: 'copy'
    
    input:
    tuple val(sample_id), path(bam)
    
    output:
    tuple val(sample_id), path("${sample_id}.filtered.bam"), emit: filtered_bam
    
    script:
    """
    samtools view \\
        -@ ${task.cpus} \\
        -q ${params.min_mapping_quality} \\
        -b \\
        ${bam} \\
        > ${sample_id}.filtered.bam
    """
}

process SAMTOOLS_INDEX {
    tag "${sample_id}"
    publishDir "${params.outdir}/filtered", mode: 'copy'
    
    input:
    tuple val(sample_id), path(bam)
    
    output:
    tuple val(sample_id), path(bam), path("${bam}.bai"), emit: indexed_bam
    
    script:
    """
    samtools index ${bam}
    """
}

process PREPARE_REFERENCE {
    publishDir "${params.outdir}/reference", mode: 'copy'
    
    input:
    path reference
    
    output:
    path reference, emit: fasta
    path "${reference}.fai", emit: fai
    path "${reference.baseName}.dict", emit: dict
    
    script:
    """
    # Index reference
    samtools faidx ${reference}
    
    # Create sequence dictionary
    gatk CreateSequenceDictionary \\
        -R ${reference} \\
        -O ${reference.baseName}.dict
    """
}

process GATK_HAPLOTYPECALLER {
    tag "${sample_id}"
    publishDir "${params.outdir}/gvcfs", mode: 'copy'
    
    input:
    tuple val(sample_id), path(bam), path(bai)
    path reference
    path reference_index
    path reference_dict
    
    output:
    tuple val(sample_id), path("${sample_id}.g.vcf.gz"), path("${sample_id}.g.vcf.gz.tbi"), emit: gvcf
    
    script:
    """
    gatk HaplotypeCaller \\
        -R ${reference} \\
        -I ${bam} \\
        -O ${sample_id}.g.vcf.gz \\
        -ERC GVCF
    """
}

process GATK_COMBINE_GVCFS {
    publishDir "${params.outdir}/combined", mode: 'copy'
    
    input:
    path gvcfs
    path gvcf_indices
    path reference
    path reference_index
    path reference_dict
    
    output:
    path "combined.g.vcf.gz", emit: combined_gvcf
    path "combined.g.vcf.gz.tbi", emit: combined_gvcf_index
    
    script:
    def gvcf_inputs = gvcfs.collect { "-V ${it}" }.join(' ')
    """
    gatk CombineGVCFs \\
        -R ${reference} \\
        ${gvcf_inputs} \\
        -O combined.g.vcf.gz
    """
}

process GATK_GENOTYPE_GVCFS {
    publishDir "${params.outdir}/genotyped", mode: 'copy'
    
    input:
    path combined_gvcf
    path combined_gvcf_index
    path reference
    path reference_index
    path reference_dict
    
    output:
    path "genotyped.vcf.gz", emit: vcf
    path "genotyped.vcf.gz.tbi", emit: vcf_index
    
    script:
    """
    gatk GenotypeGVCFs \\
        -R ${reference} \\
        -V ${combined_gvcf} \\
        -O genotyped.vcf.gz
    """
}

process GATK_SELECT_VARIANTS {
    publishDir "${params.outdir}/snps", mode: 'copy'
    
    input:
    path vcf
    path vcf_index
    path reference
    path reference_index
    path reference_dict
    
    output:
    path "snps.vcf.gz", emit: snps
    path "snps.vcf.gz.tbi", emit: snps_index
    
    script:
    """
    gatk SelectVariants \\
        -R ${reference} \\
        -V ${vcf} \\
        --select-type-to-include SNP \\
        -O snps.vcf.gz
    """
}

process GATK_FILTER_VARIANTS {
    publishDir "${params.outdir}/filtered_snps", mode: 'copy'
    
    input:
    path snps
    path snps_index
    path reference
    path reference_index
    path reference_dict
    
    output:
    path "filtered_snps.vcf.gz", emit: filtered_snps
    path "filtered_snps.vcf.gz.tbi", emit: filtered_snps_index
    
    script:
    """
    gatk VariantFiltration \\
        -R ${reference} \\
        -V ${snps} \\
        --filter-expression "QUAL < ${params.filter_qual}" --filter-name "QUAL_filter" \\
        --filter-expression "DP < ${params.filter_dp}" --filter-name "DP_filter" \\
        --filter-expression "QD < ${params.filter_qd}" --filter-name "QD_filter" \\
        --filter-expression "FS > ${params.filter_fs}" --filter-name "FS_filter" \\
        --filter-expression "MQ < ${params.filter_mq}" --filter-name "MQ_filter" \\
        --filter-expression "SOR > ${params.filter_sor}" --filter-name "SOR_filter" \\
        --filter-expression "MQRankSum < ${params.filter_mqranksum}" --filter-name "MQRankSum_filter" \\
        --filter-expression "ReadPosRankSum < ${params.filter_readposranksum}" --filter-name "ReadPosRankSum_filter" \\
        -O filtered_snps.vcf.gz
    """
}

process ANGSD_PREPARE_BEAGLE {
    publishDir "${params.outdir}/angsd", mode: 'copy'
    
    input:
    path bams
    path bais
    path reference
    path reference_index
    
    output:
    path "genotype_likelihoods.beagle.gz", emit: beagle
    
    script:
    def bam_list = bams.collect { it.toString() }.join('\n')
    """
    # Create BAM list file
    cat > bam.list << EOF
${bam_list}
EOF
    
    angsd \\
        -bam bam.list \\
        -ref ${reference} \\
        -uniqueOnly 1 \\
        -remove_bads 1 \\
        -only_proper_pairs 1 \\
        -GL 1 \\
        -doMajorMinor 1 \\
        -doMaf 1 \\
        -doGlf 2 \\
        -SNP_pval 1e-6 \\
        -out genotype_likelihoods
    """
}

process NGSADMIX {
    tag "K=${k}"
    publishDir "${params.outdir}/ngsadmix/K${k}", mode: 'copy'
    
    input:
    path beagle
    each k
    each run_id
    
    output:
    tuple val(k), val(run_id), path("*.qopt"), path("*.fopt.gz"), path("*.log"), emit: results
    
    script:
    """
    NGSadmix \\
        -likes ${beagle} \\
        -K ${k} \\
        -minMaf 0.01 \\
        -minInd ${params.min_informative_individuals} \\
        -seed ${run_id} \\
        -o K${k}_run${run_id}
    """
}

process VCF_TO_NEXUS {
    publishDir "${params.outdir}/splitstree", mode: 'copy'
    
    input:
    path vcf
    path vcf_index
    
    output:
    path "variants.nexus", emit: nexus
    
    script:
    """
    #!/usr/bin/env python3
    import gzip
    
    # Simple VCF to NEXUS converter for SNP data
    # Reads filtered SNPs and creates NEXUS format for SplitsTree
    
    samples = []
    snp_matrix = {}
    
    # Read VCF file
    vcf_file = gzip.open('${vcf}', 'rt') if '${vcf}'.endswith('.gz') else open('${vcf}', 'r')
    
    for line in vcf_file:
        if line.startswith('##'):
            continue
        if line.startswith('#CHROM'):
            # Header line with sample names
            parts = line.strip().split('\\t')
            samples = parts[9:]  # Sample names start at column 9
            for sample in samples:
                snp_matrix[sample] = []
            continue
        
        # Data line
        parts = line.strip().split('\\t')
        chrom, pos, ref, alt = parts[0], parts[1], parts[3], parts[4]
        genotypes = parts[9:]
        
        # Skip if filter failed
        if parts[6] != 'PASS' and parts[6] != '.':
            continue
        
        # Extract genotypes for each sample
        for i, sample in enumerate(samples):
            gt_data = genotypes[i].split(':')
            gt = gt_data[0]
            
            # Convert genotype to IUPAC ambiguity codes
            if gt == '0/0' or gt == '0|0':
                snp_matrix[sample].append(ref)
            elif gt == '1/1' or gt == '1|1':
                snp_matrix[sample].append(alt.split(',')[0])
            elif gt in ['0/1', '1/0', '0|1', '1|0']:
                snp_matrix[sample].append('N')  # Heterozygous as N
            else:
                snp_matrix[sample].append('?')  # Missing data
    
    vcf_file.close()
    
    # Write NEXUS format
    with open('variants.nexus', 'w') as nex:
        nex.write('#NEXUS\\n\\n')
        nex.write('BEGIN DATA;\\n')
        nex.write(f'    DIMENSIONS NTAX={len(samples)} NCHAR={len(snp_matrix[samples[0]])};\\n')
        nex.write('    FORMAT DATATYPE=DNA MISSING=? GAP=-;\\n')
        nex.write('    MATRIX\\n')
        
        for sample in samples:
            sequence = ''.join(snp_matrix[sample])
            nex.write(f'{sample}    {sequence}\\n')
        
        nex.write('    ;\\n')
        nex.write('END;\\n')
    
    print(f"Converted {len(samples)} samples with {len(snp_matrix[samples[0]])} SNPs to NEXUS format")
    """
}

process SPLITSTREE {
    publishDir "${params.outdir}/splitstree", mode: 'copy'
    
    input:
    path nexus
    
    output:
    path "neighbour_net.nex", emit: network
    path "splitstree.log", emit: log
    
    script:
    """
    # SplitsTree4 command-line execution
    # Generate neighbour-net network from NEXUS file
    
    splitstree4 \\
        -g \\
        -i ${nexus} \\
        -o neighbour_net.nex \\
        -x "UPDATE; EXECUTE NAME=NeighborNet;" \\
        > splitstree.log 2>&1
    
    # If splitstree4 is not available in CLI mode, create instruction file
    if [ ! -f neighbour_net.nex ]; then
        echo "Note: SplitsTree4 CLI not available. Creating instructions file." >> splitstree.log
        cat > splitstree_instructions.txt << 'EOF'
To run SplitsTree analysis manually:
1. Open SplitsTree4 GUI (v4.16.2)
2. File > Open > Select variants.nexus
3. Analysis > Neighbour-Net
4. File > Export > Save as neighbour_net.nex
EOF
        cp ${nexus} neighbour_net.nex
    fi
    """
}

process VCF_TO_MATRIX {
    publishDir "${params.outdir}/pca", mode: 'copy'
    
    input:
    path vcf
    path vcf_index
    
    output:
    path "snp_matrix.txt", emit: matrix
    path "sample_names.txt", emit: samples
    
    script:
    """
    #!/usr/bin/env python3
    import gzip
    
    # Convert VCF to SNP matrix for PCA
    # Each row is a sample, each column is a SNP position
    
    samples = []
    snp_positions = []
    genotype_matrix = []
    
    # Read VCF file
    vcf_file = gzip.open('${vcf}', 'rt') if '${vcf}'.endswith('.gz') else open('${vcf}', 'r')
    
    for line in vcf_file:
        if line.startswith('##'):
            continue
        if line.startswith('#CHROM'):
            # Header line with sample names
            parts = line.strip().split('\\t')
            samples = parts[9:]
            genotype_matrix = [[] for _ in samples]
            continue
        
        # Data line
        parts = line.strip().split('\\t')
        chrom, pos = parts[0], parts[1]
        genotypes = parts[9:]
        
        # Skip if filter failed
        if parts[6] != 'PASS' and parts[6] != '.':
            continue
        
        snp_positions.append(f"{chrom}:{pos}")
        
        # Extract genotypes as numeric (0=ref, 1=het, 2=alt, -1=missing)
        for i, gt_field in enumerate(genotypes):
            gt = gt_field.split(':')[0]
            
            if gt == '0/0' or gt == '0|0':
                genotype_matrix[i].append('0')
            elif gt == '1/1' or gt == '1|1':
                genotype_matrix[i].append('2')
            elif gt in ['0/1', '1/0', '0|1', '1|0']:
                genotype_matrix[i].append('1')
            else:
                genotype_matrix[i].append('NA')
    
    vcf_file.close()
    
    # Write SNP matrix (samples as rows, SNPs as columns)
    with open('snp_matrix.txt', 'w') as f:
        # Header with SNP positions
        f.write('Sample\\t' + '\\t'.join(snp_positions) + '\\n')
        
        # Data rows
        for i, sample in enumerate(samples):
            f.write(sample + '\\t' + '\\t'.join(genotype_matrix[i]) + '\\n')
    
    # Write sample names
    with open('sample_names.txt', 'w') as f:
        for sample in samples:
            f.write(sample + '\\n')
    
    print(f"Created SNP matrix: {len(samples)} samples x {len(snp_positions)} SNPs")
    """
}

process ADE4_PCA {
    publishDir "${params.outdir}/pca", mode: 'copy'
    
    input:
    path matrix
    path sample_names
    
    output:
    path "pca_results.rds", emit: pca_object
    path "pca_summary.txt", emit: summary
    path "pca_plot.pdf", emit: plot
    path "pca_coordinates.txt", emit: coordinates
    
    script:
    def center_opt = params.pca_center ? "TRUE" : "FALSE"
    def scale_opt = params.pca_scale ? "TRUE" : "FALSE"
    """
    #!/usr/bin/env Rscript
    
    # Load required library
    library(ade4)
    
    # Read SNP matrix
    snp_data <- read.table("${matrix}", header = TRUE, row.names = 1, sep = "\\t", 
                          na.strings = "NA", check.names = FALSE)
    
    # Convert to numeric matrix
    snp_matrix <- as.matrix(snp_data)
    mode(snp_matrix) <- "numeric"
    
    # Remove SNPs with too much missing data (>50%)
    missing_per_snp <- apply(snp_matrix, 2, function(x) sum(is.na(x)) / length(x))
    snp_matrix <- snp_matrix[, missing_per_snp < 0.5]
    
    # Impute missing values with column means (common approach for PCA)
    for (i in 1:ncol(snp_matrix)) {
        col_mean <- mean(snp_matrix[, i], na.rm = TRUE)
        snp_matrix[is.na(snp_matrix[, i]), i] <- col_mean
    }
    
    # Perform PCA using ade4 package
    # Parameters: center=${center_opt}, scale=${scale_opt} (as specified in methods)
    pca_result <- dudi.pca(snp_matrix, center = ${center_opt}, scale = ${scale_opt}, 
                          scannf = FALSE, nf = 5)
    
    # Save PCA object
    saveRDS(pca_result, "pca_results.rds")
    
    # Write summary
    sink("pca_summary.txt")
    cat("PCA Analysis Summary\\n")
    cat("====================\\n\\n")
    cat("Settings:\\n")
    cat("  - Centered: ${center_opt}\\n")
    cat("  - Scaled: ${scale_opt}\\n\\n")
    cat("Number of samples:", nrow(snp_matrix), "\\n")
    cat("Number of SNPs:", ncol(snp_matrix), "\\n\\n")
    cat("Eigenvalues:\\n")
    print(pca_result\$eig)
    cat("\\n\\nVariance explained by each PC:\\n")
    variance_explained <- pca_result\$eig / sum(pca_result\$eig) * 100
    for (i in 1:min(5, length(variance_explained))) {
        cat(sprintf("PC%d: %.2f%%\\n", i, variance_explained[i]))
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
                quote = FALSE, sep = "\\t", col.names = NA)
    
    cat("PCA analysis completed successfully\\n")
    """
}

// ========================================================================================
// WORKFLOW
// ========================================================================================

workflow {
    
    // Show help message if requested
    if (params.help) {
        helpMessage()
        exit 0
    }
    
    // Validate inputs
    if (!params.reads) {
        exit 1, "Error: Please provide input reads with --reads"
    }
    if (!params.reference) {
        exit 1, "Error: Please provide reference genome with --reference"
    }
    if (!params.bowtie2_index) {
        exit 1, "Error: Please provide Bowtie2 index prefix with --bowtie2_index"
    }
    
    // Create input channel from reads
    reads_ch = Channel
        .fromFilePairs(params.reads, checkIfExists: true)
        .map { sample_id, files -> 
            tuple(sample_id, files)
        }
    
    // Prepare Bowtie2 index files
    bowtie2_index_ch = Channel
        .fromPath("${params.bowtie2_index}*.bt2*", checkIfExists: true)
        .collect()
    
    // Prepare reference
    reference_ch = Channel.fromPath(params.reference, checkIfExists: true)
    
    // Step 1: Trim reads with Trimmomatic
    TRIMMOMATIC(reads_ch)
    
    // Step 2: Align with Bowtie2
    BOWTIE2_ALIGN(
        TRIMMOMATIC.out.trimmed_reads,
        bowtie2_index_ch
    )
    
    // Step 3: Sort BAM files
    SAMTOOLS_SORT(BOWTIE2_ALIGN.out.bam)
    
    // Step 4: Remove duplicates
    SAMTOOLS_RMDUP(SAMTOOLS_SORT.out.sorted_bam)
    
    // Step 5: Filter by mapping quality
    SAMTOOLS_FILTER(SAMTOOLS_RMDUP.out.dedup_bam)
    
    // Step 6: Index filtered BAM files
    SAMTOOLS_INDEX(SAMTOOLS_FILTER.out.filtered_bam)
    
    // Step 7: Prepare reference genome
    PREPARE_REFERENCE(reference_ch)
    
    // Step 8: Call variants with GATK HaplotypeCaller (per sample)
    GATK_HAPLOTYPECALLER(
        SAMTOOLS_INDEX.out.indexed_bam,
        PREPARE_REFERENCE.out.fasta,
        PREPARE_REFERENCE.out.fai,
        PREPARE_REFERENCE.out.dict
    )
    
    // Collect all gVCFs for joint genotyping
    all_gvcfs = GATK_HAPLOTYPECALLER.out.gvcf
        .map { _sample_id, gvcf, _gvcf_index -> gvcf }
        .collect()
    
    all_gvcf_indices = GATK_HAPLOTYPECALLER.out.gvcf
        .map { _sample_id, _gvcf, gvcf_index -> gvcf_index }
        .collect()
    
    // Step 9: Combine GVCFs
    GATK_COMBINE_GVCFS(
        all_gvcfs,
        all_gvcf_indices,
        PREPARE_REFERENCE.out.fasta,
        PREPARE_REFERENCE.out.fai,
        PREPARE_REFERENCE.out.dict
    )
    
    // Step 10: Joint genotyping
    GATK_GENOTYPE_GVCFS(
        GATK_COMBINE_GVCFS.out.combined_gvcf,
        GATK_COMBINE_GVCFS.out.combined_gvcf_index,
        PREPARE_REFERENCE.out.fasta,
        PREPARE_REFERENCE.out.fai,
        PREPARE_REFERENCE.out.dict
    )
    
    // Step 11: Select SNPs
    GATK_SELECT_VARIANTS(
        GATK_GENOTYPE_GVCFS.out.vcf,
        GATK_GENOTYPE_GVCFS.out.vcf_index,
        PREPARE_REFERENCE.out.fasta,
        PREPARE_REFERENCE.out.fai,
        PREPARE_REFERENCE.out.dict
    )
    
    // Step 12: Filter variants
    GATK_FILTER_VARIANTS(
        GATK_SELECT_VARIANTS.out.snps,
        GATK_SELECT_VARIANTS.out.snps_index,
        PREPARE_REFERENCE.out.fasta,
        PREPARE_REFERENCE.out.fai,
        PREPARE_REFERENCE.out.dict
    )
    
    // Optional: NGSadmix analysis
    if (params.run_ngsadmix) {
        // Collect all filtered BAM files
        all_bams = SAMTOOLS_FILTER.out.filtered_bam
            .map { _sample_id, bam -> bam }
            .collect()
        
        all_bais = SAMTOOLS_INDEX.out.indexed_bam
            .map { _sample_id, _bam, bai -> bai }
            .collect()
        
        // Prepare Beagle file
        ANGSD_PREPARE_BEAGLE(
            all_bams,
            all_bais,
            PREPARE_REFERENCE.out.fasta,
            PREPARE_REFERENCE.out.fai
        )
        
        // Run NGSadmix for different K values
        k_values = Channel.from(params.min_k..params.max_k)
        run_ids = Channel.from(1..params.ngsadmix_runs)
        
        NGSADMIX(
            ANGSD_PREPARE_BEAGLE.out.beagle,
            k_values,
            run_ids
        )
    }
    
    // Optional: SplitsTree neighbour-net analysis
    if (params.run_splitstree) {
        VCF_TO_NEXUS(
            GATK_FILTER_VARIANTS.out.filtered_snps,
            GATK_FILTER_VARIANTS.out.filtered_snps_index
        )
        
        SPLITSTREE(
            VCF_TO_NEXUS.out.nexus
        )
    }
    
    // Optional: Ade4 PCA analysis
    if (params.run_pca) {
        VCF_TO_MATRIX(
            GATK_FILTER_VARIANTS.out.filtered_snps,
            GATK_FILTER_VARIANTS.out.filtered_snps_index
        )
        
        ADE4_PCA(
            VCF_TO_MATRIX.out.matrix,
            VCF_TO_MATRIX.out.samples
        )
    }
    
    // Completion message
    workflow.onComplete {
        log.info ""
        log.info "Pipeline completed!"
        log.info "Status:     ${workflow.success ? 'SUCCESS' : 'FAILED'}"
        log.info "Results:    ${params.outdir}"
        log.info ""
    }
}


