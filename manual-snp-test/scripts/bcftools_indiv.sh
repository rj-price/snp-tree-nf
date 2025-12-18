#!/usr/bin/env bash
#SBATCH -J bcftools
#SBATCH --partition=medium
#SBATCH --mem=1G
#SBATCH --cpus-per-task=4

# INPUTS
Ref=$1
BAM=$2
OutPrefix=$3

source activate variant_calling

bcftools mpileup --threads 8 -Ou -m 10 -d 1000 -f $Ref $BAM |
    bcftools call --threads 8 -mv --ploidy 1 -o "$OutPrefix"_calls.vcf


TOTAL=$(bcftools view -H "$OutPrefix"_calls.vcf | wc -l)
SNPS=$(bcftools view -H "$OutPrefix"_calls.vcf --types snps | wc -l)
INDELS=$(bcftools view -H "$OutPrefix"_calls.vcf --types indels | wc -l)

echo ""
echo "=========== VARIANT CALLING ==========="
echo "Total Variants = $TOTAL"
echo "Total SNPs = $SNPS"
echo "Total INDELs = $INDELS"
echo ""
grep -v '^#' "$OutPrefix"_calls.vcf | awk 'BEGIN {max=0} {sum+=$6; if ($6>max) {max=$6}} END {print "Average qual: "sum/NR "\tMax qual: " max}' 
echo "======================================="
