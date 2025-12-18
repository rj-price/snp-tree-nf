#!/bin/bash
#SBATCH -J multiqc
#SBATCH --partition=short
#SBATCH --mem=2G
#SBATCH --cpus-per-task=2

FastQC_Dir=$1

apptainer exec --bind /mnt/shared:/mnt/shared --bind ~/scratch:/scratch $APPS/singularity_cache/community.wave.seqera.io-library-multiqc-1.25.1--dc1968330462e945.img \
	multiqc $FastQC_Dir