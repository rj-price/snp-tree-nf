#!/bin/bash

# Example Usage Script for P. roqueforti Variant Calling Pipeline
# This script demonstrates how to run the pipeline with different configurations

# ============================================================================
# Basic Usage with Docker
# ============================================================================
nextflow run main.nf \
    --reads 'data/*_R{1,2}.fastq.gz' \
    --reference genome/reference.fasta \
    --bowtie2_index genome/reference \
    --outdir results \
    -profile docker

# ============================================================================
# Usage with Singularity
# ============================================================================
nextflow run main.nf \
    --reads 'data/*_R{1,2}.fastq.gz' \
    --reference genome/reference.fasta \
    --bowtie2_index genome/reference \
    --outdir results \
    -profile singularity

# ============================================================================
# Usage with Conda
# ============================================================================
nextflow run main.nf \
    --reads 'data/*_R{1,2}.fastq.gz' \
    --reference genome/reference.fasta \
    --bowtie2_index genome/reference \
    --outdir results \
    -profile conda

# ============================================================================
# Usage with Custom Parameters
# ============================================================================
nextflow run main.nf \
    --reads 'data/*_R{1,2}.fastq.gz' \
    --reference genome/reference.fasta \
    --bowtie2_index genome/reference \
    --adapters adapters/TruSeq3-PE.fa \
    --outdir results \
    --leading 5 \
    --trailing 5 \
    --minlen 40 \
    --min_mapping_quality 20 \
    --filter_qual 50 \
    --filter_dp 15 \
    -profile docker

# ============================================================================
# Usage with NGSadmix Analysis
# ============================================================================
nextflow run main.nf \
    --reads 'data/*_R{1,2}.fastq.gz' \
    --reference genome/reference.fasta \
    --bowtie2_index genome/reference \
    --outdir results \
    --run_ngsadmix true \
    --min_k 2 \
    --max_k 6 \
    --ngsadmix_runs 100 \
    -profile docker

# ============================================================================
# Usage with SplitsTree Neighbour-Net Analysis
# ============================================================================
nextflow run main.nf \
    --reads 'data/*_R{1,2}.fastq.gz' \
    --reference genome/reference.fasta \
    --bowtie2_index genome/reference \
    --outdir results \
    --run_splitstree true \
    -profile docker

# ============================================================================
# Usage with Ade4 PCA Analysis (centered and unscaled)
# ============================================================================
nextflow run main.nf \
    --reads 'data/*_R{1,2}.fastq.gz' \
    --reference genome/reference.fasta \
    --bowtie2_index genome/reference \
    --outdir results \
    --run_pca true \
    --pca_center true \
    --pca_scale false \
    -profile docker

# ============================================================================
# Usage with All Downstream Analyses
# ============================================================================
nextflow run main.nf \
    --reads 'data/*_R{1,2}.fastq.gz' \
    --reference genome/reference.fasta \
    --bowtie2_index genome/reference \
    --outdir results \
    --run_ngsadmix true \
    --run_splitstree true \
    --run_pca true \
    --min_k 2 \
    --max_k 6 \
    --ngsadmix_runs 100 \
    -profile docker

# ============================================================================
# Usage on SLURM Cluster
# ============================================================================
nextflow run main.nf \
    --reads 'data/*_R{1,2}.fastq.gz' \
    --reference genome/reference.fasta \
    --bowtie2_index genome/reference \
    --outdir results \
    -profile slurm,singularity

# ============================================================================
# Usage on AWS Batch
# ============================================================================
nextflow run main.nf \
    --reads 's3://my-bucket/data/*_R{1,2}.fastq.gz' \
    --reference 's3://my-bucket/genome/reference.fasta' \
    --bowtie2_index 's3://my-bucket/genome/reference' \
    --outdir 's3://my-bucket/results' \
    -profile awsbatch

# ============================================================================
# Resume a Failed Run
# ============================================================================
nextflow run main.nf \
    --reads 'data/*_R{1,2}.fastq.gz' \
    --reference genome/reference.fasta \
    --bowtie2_index genome/reference \
    --outdir results \
    -profile docker \
    -resume

# ============================================================================
# Show Help Message
# ============================================================================
nextflow run main.nf --help
