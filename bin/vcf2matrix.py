#!/usr/bin/env python3
import gzip
import sys
import argparse

def vcf_to_matrix(vcf_path, out_matrix, out_samples):
    # Convert VCF to SNP matrix for PCA
    # Each row is a sample, each column is a SNP position
    
    samples = []
    snp_positions = []
    genotype_matrix = []
    
    # Read VCF file
    if vcf_path.endswith('.gz'):
        vcf_file = gzip.open(vcf_path, 'rt')
    else:
        vcf_file = open(vcf_path, 'r')
    
    for line in vcf_file:
        if line.startswith('##'):
            continue
        if line.startswith('#CHROM'):
            # Header line with sample names
            parts = line.strip().split('	')
            samples = parts[9:]
            genotype_matrix = [[] for _ in samples]
            continue
        
        # Data line
        parts = line.strip().split('	')
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
    with open(out_matrix, 'w') as f:
        # Header with SNP positions
        f.write('Sample	' + '	'.join(snp_positions) + '
')
        
        # Data rows
        for i, sample in enumerate(samples):
            f.write(sample + '	' + '	'.join(genotype_matrix[i]) + '
')
    
    # Write sample names
    with open(out_samples, 'w') as f:
        for sample in samples:
            f.write(sample + '
')
    
    print(f"Created SNP matrix: {len(samples)} samples x {len(snp_positions)} SNPs")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Convert VCF to SNP matrix')
    parser.add_argument('--vcf', required=True, help='Input VCF file')
    parser.add_argument('--matrix', required=True, help='Output matrix file')
    parser.add_argument('--samples', required=True, help='Output sample names file')
    args = parser.parse_args()
    
    vcf_to_matrix(args.vcf, args.matrix, args.samples)
