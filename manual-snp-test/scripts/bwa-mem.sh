#!/usr/bin/env bash
#SBATCH -J bwa-mem
#SBATCH --partition=medium
#SBATCH --mem=8G
#SBATCH --cpus-per-task=4

refAssembly=$1
F_Read=$2
R_Read=$3

source activate variant_calling

Prefix=$(basename $F_Read | sed 's/_1.fastq.gz//')

bwa mem -t 8 $refAssembly $F_Read $R_Read > $Prefix.sam

samtools flagstat -@ 8 $Prefix.sam

samtools view -@ 8 -bS $Prefix.sam -o $Prefix.bam
samtools sort -@ 8 $Prefix.bam -o "$Prefix"_sorted.bam
samtools index -@ 8 "$Prefix"_sorted.bam

samtools depth "$Prefix"_sorted.bam > $Prefix.depth
awk '{cov[$1]+=$3; len[$1]+=1} END {for (contig in cov) print contig, cov[contig]/len[contig]}' $Prefix.depth > "$Prefix".depth_per_contig

rm $Prefix.sam
rm $Prefix.bam
rm $Prefix.depth