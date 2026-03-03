#!/usr/bin/env python3
"""
Convert VCF files to PHYLIP format for phylogenetic analysis.
Combines multiple VCF files into a single alignment matrix.
"""

import sys
import argparse
import gzip
from pathlib import Path
from collections import defaultdict


def parse_args(args=None):
    parser = argparse.ArgumentParser(
        description="Convert VCF files to PHYLIP format"
    )
    parser.add_argument(
        "--input",
        nargs="+",
        type=Path,
        required=True,
        help="Input VCF files (can be gzipped)"
    )
    parser.add_argument(
        "--output",
        type=Path,
        required=True,
        help="Output PHYLIP file"
    )
    return parser.parse_args(args)


def open_file(filepath):
    """Open regular or gzipped file."""
    if str(filepath).endswith('.gz'):
        return gzip.open(filepath, 'rt')
    return open(filepath, 'r')


def parse_vcf(vcf_files):
    """Parse VCF files and extract SNP matrix."""
    samples = []
    positions = []
    genotypes = defaultdict(list)
    
    for vcf_file in vcf_files:
        with open_file(vcf_file) as f:
            for line in f:
                if line.startswith('##'):
                    continue
                elif line.startswith('#CHROM'):
                    # Extract sample names
                    fields = line.strip().split('\t')
                    samples = fields[9:]
                    for sample in samples:
                        if sample not in genotypes:
                            genotypes[sample] = []
                else:
                    # Parse variant line
                    fields = line.strip().split('\t')
                    chrom = fields[0]
                    pos = fields[1]
                    ref = fields[3]
                    alt = fields[4]
                    
                    # Store position
                    positions.append(f"{chrom}:{pos}")
                    
                    # Extract genotypes for each sample
                    for i, sample in enumerate(samples):
                        gt_field = fields[9 + i].split(':')[0]
                        
                        # Convert genotype to nucleotide
                        if gt_field in ['0/0', '0|0']:
                            genotypes[sample].append(ref)
                        elif gt_field in ['1/1', '1|1']:
                            genotypes[sample].append(alt.split(',')[0])
                        elif gt_field in ['0/1', '0|1', '1/0', '1|0']:
                            # Heterozygous - use IUPAC ambiguity code or just reference
                            genotypes[sample].append(ref)
                        else:
                            # Missing data
                            genotypes[sample].append('N')
    
    return samples, genotypes, len(positions)


def write_phylip(samples, genotypes, num_sites, output_file):
    """Write alignment in PHYLIP format."""
    with open(output_file, 'w') as f:
        # Header line: number of sequences and sequence length
        f.write(f"{len(samples)} {num_sites}\n")
        
        # Write each sequence
        for sample in samples:
            sequence = ''.join(genotypes[sample])
            # Relaxed PHYLIP format: name followed by space then sequence
            f.write(f"{sample} {sequence}\n")


def main(args=None):
    args = parse_args(args)
    
    print(f"Parsing {len(args.input)} VCF file(s)...", file=sys.stderr)
    samples, genotypes, num_sites = parse_vcf(args.input)
    
    print(f"Found {len(samples)} samples with {num_sites} variant sites", file=sys.stderr)
    
    print(f"Writing PHYLIP alignment to {args.output}...", file=sys.stderr)
    write_phylip(samples, genotypes, num_sites, args.output)
    
    print("Done!", file=sys.stderr)


if __name__ == '__main__':
    main()
