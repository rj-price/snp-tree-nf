#!/usr/bin/env bash
#SBATCH -J bcftools
#SBATCH --partition=long
#SBATCH --mem=8G
#SBATCH --cpus-per-task=4

# INPUTS
Ref=$1
BAMlist=$2
OutPrefix=$3

source activate variant_calling

bcftools mpileup --threads 8 -Ou -m 10 -d 4000 -f $Ref -b $BAMlist | \
    bcftools call --threads 8 -cv --ploidy 1 -o $OutPrefix.vcf


TOTAL=$(bcftools view -H $OutPrefix.vcf | wc -l)
SNPS=$(bcftools view -H $OutPrefix.vcf --types snps | wc -l)
INDELS=$(bcftools view -H $OutPrefix.vcf --types indels | wc -l)

echo ""
echo "=========== VARIANT CALLING ==========="
echo "Total Variants = $TOTAL"
echo "Total SNPs = $SNPS"
echo "Total INDELs = $INDELS"
echo ""
grep -v '^#' $OutPrefix.vcf | awk 'BEGIN {max=0} {sum+=$6; if ($6>max) {max=$6}} END {print "Average qual: "sum/NR "\tMax qual: " max}' 
echo "======================================="
