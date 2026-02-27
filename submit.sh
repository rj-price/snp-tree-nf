#!/usr/bin/env bash
#SBATCH -J snp-tree-nf
#SBATCH --partition=medium
#SBATCH --mem=64G
#SBATCH --cpus-per-task=8

# Activate conda environment (if needed)
# source activate nextflow

nextflow run main.nf \
    --input samplesheet.csv \
    --fasta ref/GCA_030518555.1_ASM3051855v1_genomic.fna \
    --adapters TruSeq3-PE.fa \
    --outdir results \
    -resume
