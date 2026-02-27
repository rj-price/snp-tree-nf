#!/usr/bin/env python3
"""
Validate and parse samplesheet CSV file.
Expected format: sample_id,read1,read2
"""

import sys
import csv
import argparse
from pathlib import Path


def parse_args(args=None):
    parser = argparse.ArgumentParser(
        description="Validate samplesheet format and check for duplicates."
    )
    parser.add_argument(
        "samplesheet",
        type=Path,
        help="Input samplesheet CSV file"
    )
    parser.add_argument(
        "output",
        type=Path,
        help="Output validated samplesheet CSV file"
    )
    return parser.parse_args(args)


def check_samplesheet(samplesheet, output):
    """
    Validate samplesheet format and check for duplicate sample IDs.
    """
    seen_samples = set()
    
    with open(samplesheet, 'r') as fin, open(output, 'w') as fout:
        reader = csv.DictReader(fin)
        writer = csv.DictWriter(fout, fieldnames=['sample_id', 'read1', 'read2'])
        writer.writeheader()
        
        # Check required columns
        required_cols = {'sample_id', 'read1', 'read2'}
        if not required_cols.issubset(reader.fieldnames):
            sys.exit(f"ERROR: Samplesheet must contain columns: {', '.join(required_cols)}")
        
        for i, row in enumerate(reader, start=2):
            sample_id = row['sample_id'].strip()
            read1 = row['read1'].strip()
            read2 = row['read2'].strip()
            
            # Check for empty fields
            if not sample_id:
                sys.exit(f"ERROR: Line {i}: sample_id cannot be empty")
            if not read1:
                sys.exit(f"ERROR: Line {i}: read1 cannot be empty")
            if not read2:
                sys.exit(f"ERROR: Line {i}: read2 cannot be empty")
            
            # Check for duplicate sample IDs
            if sample_id in seen_samples:
                sys.exit(f"ERROR: Duplicate sample_id found: {sample_id}")
            seen_samples.add(sample_id)
            
            # Write validated row
            writer.writerow({
                'sample_id': sample_id,
                'read1': read1,
                'read2': read2
            })


def main(args=None):
    args = parse_args(args)
    check_samplesheet(args.samplesheet, args.output)


if __name__ == '__main__':
    main()
