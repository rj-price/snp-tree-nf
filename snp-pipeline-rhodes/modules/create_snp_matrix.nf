process CREATE_SNP_MATRIX {
    label 'process_low'
    publishDir "${params.outdir}/phylogenetics", mode: 'copy'

    input:
    path vcfs
    path reference

    output:
    path "snp_matrix.phylip", emit: phylip

    script:
    """
    #!/usr/bin/env python3
    
    import sys
    from collections import defaultdict
    
    # Parse all VCF files
    vcf_files = "${vcfs}".split()
    
    # Store SNP positions and genotypes
    snp_positions = set()
    sample_genotypes = defaultdict(dict)
    
    for vcf_file in vcf_files:
        sample_name = vcf_file.replace('.filtered.vcf.gz', '').replace('.vcf.gz', '').replace('.vcf', '')
        
        # Handle compressed VCF files
        import gzip
        
        if vcf_file.endswith('.gz'):
            f = gzip.open(vcf_file, 'rt')
        else:
            f = open(vcf_file, 'r')
        
            for line in f:
                if line.startswith('#'):
                    continue
                
                fields = line.strip().split('\\t')
                chrom = fields[0]
                pos = fields[1]
                ref = fields[3]
                alt = fields[4]
                qual = fields[5]
                filter_field = fields[6]
                
                # Skip low confidence variants (converted to missing data)
                if filter_field != 'PASS' and filter_field != '.':
                    position_key = f"{chrom}:{pos}"
                    sample_genotypes[sample_name][position_key] = 'N'
                    snp_positions.add(position_key)
                    continue
                
                # Create SNP presence/absence call
                # 0 = matches reference, 1 = has SNP
                if len(fields) >= 10:
                    gt_field = fields[9].split(':')[0]
                    
                    position_key = f"{chrom}:{pos}"
                    snp_positions.add(position_key)
                    
                    if gt_field in ['0/0', '0|0']:
                        sample_genotypes[sample_name][position_key] = '0'
                    elif gt_field in ['1/1', '1|1', '0/1', '1/0', '0|1', '1|0']:
                        sample_genotypes[sample_name][position_key] = '1'
                    else:
                        sample_genotypes[sample_name][position_key] = 'N'
        finally:
            f.close()
    
    # Sort positions
    sorted_positions = sorted(list(snp_positions))
    
    # Write relaxed interleaved Phylip format
    with open('snp_matrix.phylip', 'w') as out:
        num_samples = len(sample_genotypes)
        num_positions = len(sorted_positions)
        
        # Header line
        out.write(f"{num_samples} {num_positions}\\n")
        
        # Write sequences
        for sample_name, genotypes in sample_genotypes.items():
            sequence = ''.join([genotypes.get(pos, 'N') for pos in sorted_positions])
            # Phylip format: 10 char name, space, sequence
            out.write(f"{sample_name[:10]:<10} {sequence}\\n")
    
    print(f"Created SNP matrix with {num_samples} samples and {num_positions} SNP positions")
    """
}
