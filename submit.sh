#!/usr/bin/env bash
#SBATCH -J snp-tree-nf
#SBATCH --partition=long
#SBATCH --mem=8G
#SBATCH --cpus-per-task=4

# Activate conda environment (if needed)
source activate nextflow

nextflow run main.nf \
    -profile slurm,singularity \
    --input samplesheet.csv \
    --fasta ref/GCA_030518555.1_ASM3051855v1_genomic.fna \
    --adapters TruSeq3-PE.fa \
    --outdir results \
    #-resume
