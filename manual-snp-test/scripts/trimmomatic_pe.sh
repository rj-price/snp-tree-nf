#!/usr/bin/env bash
#SBATCH -J trimmomatic
#SBATCH --partition=medium
#SBATCH --mem=1G
#SBATCH --cpus-per-task=4

# Activate conda environment
source activate illumina_assembly

# F reads = $1 
# R reads = $2

ln -s $1
ln -s $2

file1=$(basename $1)
file2=$(basename $2)
fileshort=$(basename $1 _1.fq.gz)

#wget https://github.com/usadellab/Trimmomatic/raw/main/adapters/TruSeq3-PE.fa

trimmomatic PE -threads 8 -phred33 $file1 $file2 \
    "$fileshort"_trimmed_1.fastq.gz "$fileshort"_unpaired_1.fastq.gz \
    "$fileshort"_trimmed_2.fastq.gz "$fileshort"_unpaired_2.fastq.gz \
    ILLUMINACLIP:TruSeq3-PE.fa:2:30:10:2:keepBothReads LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 HEADCROP:10 MINLEN:60

rm $file1
rm $file2