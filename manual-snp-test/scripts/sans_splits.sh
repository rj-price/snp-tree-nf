#!/usr/bin/env bash
#SBATCH -J SANS
#SBATCH --partition=short
#SBATCH --mem=120G
#SBATCH --cpus-per-task=8

GenomeList=$1
Prefix=$(basename $GenomeList | cut -d'.' -f1)

echo "Running SANS on $GenomeList:"
echo "    SANS -T 16 -v -i $GenomeList -o $Prefix.splits -X $Prefix.nexus -t 10n -f weakly"

/mnt/apps/users/jnprice/sans/SANS -T 16 -v -i $GenomeList -o $Prefix.splits -X $Prefix.nexus -t 10n -f weakly

#sed -i 's|/mnt/shared/scratch/jnprice/private/novel_fola/Fusarium_pg/all_vs_all/parse_contigs/||g' $Prefix.new
#sed -i 's|.fasta||g' $Prefix.new