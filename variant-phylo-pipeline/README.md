# Variant Calling and Phylogenetic Analysis Pipeline

A comprehensive Nextflow pipeline for variant calling from paired-end sequencing reads and phylogenetic tree construction.

## Pipeline Overview

This pipeline performs the following steps:

1. **Quality Control (Raw)** - FastQC on raw reads
2. **Adapter Trimming** - Trimmomatic with specified parameters
3. **Quality Control (Trimmed)** - FastQC on trimmed reads
4. **Reference Indexing** - BWA index and Samtools faidx
5. **Read Alignment** - BWA-MEM with read group information
6. **BAM Processing** - Convert SAM to BAM, sort, and index
7. **Alignment Statistics** - Samtools stats
8. **Variant Calling** - BCFtools mpileup and call
9. **Variant Filtering** - Filter SNPs by quality criteria
10. **Format Conversion** - VCF to PHYLIP and NEXUS formats
11. **Phylogenetic Tree** - RAxML tree construction
12. **MultiQC Report** - Aggregated quality control report

## Requirements

### Software Dependencies

- Nextflow (>= 23.04.0)
- FastQC
- Trimmomatic
- BWA
- Samtools
- BCFtools
- RAxML
- MultiQC
- Python 3

### Container Support

The pipeline can be run with Docker, Singularity, or Conda for automatic dependency management.

## Quick Start

### 1. Prepare Input Files

Create a samplesheet CSV file with the following format:

```csv
sample_id,read1,read2
sample1,/path/to/sample1_R1.fastq.gz,/path/to/sample1_R2.fastq.gz
sample2,/path/to/sample2_R1.fastq.gz,/path/to/sample2_R2.fastq.gz
```

### 2. Run the Pipeline

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --fasta reference_genome.fa \
    --outdir results
```

### 3. With Adapter Trimming

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --fasta reference_genome.fa \
    --adapters TruSeq3-PE.fa \
    --outdir results
```

## Parameters

### Required

| Parameter | Description |
|-----------|-------------|
| `--input` | Path to samplesheet CSV file |
| `--fasta` | Path to reference genome FASTA file |

### Optional

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--adapters` | null | Path to adapter sequences for Trimmomatic |
| `--outdir` | ./results | Output directory |
| `--max_memory` | 16.GB | Maximum memory allocation |
| `--max_cpus` | 8 | Maximum CPU cores |
| `--max_time` | 48.h | Maximum time per process |

## Trimmomatic Parameters

The pipeline uses the following Trimmomatic settings:

- **ILLUMINACLIP**: 2:30:10 (if adapter file provided)
- **SLIDINGWINDOW**: 4:20
- **MINLEN**: 36
- **HEADCROP**: 10

## Variant Filtering Criteria

Variants are filtered using BCFtools with the following criteria:

- **Type**: SNPs only
- **QUAL**: ≥ 20
- **DP** (Depth): ≥ 10
- **MQ** (Mapping Quality): ≥ 30

## Output Structure

```
results/
├── fastqc/                    # FastQC reports (raw and trimmed)
│   ├── sample1/
│   └── sample2/
├── trimmomatic/               # Trimmed reads and logs
│   ├── sample1/
│   └── sample2/
├── samtools/                  # BAM files, indices, and stats
│   ├── sample1/
│   └── sample2/
├── variants/                  # VCF files (raw and filtered)
│   ├── sample1/
│   └── sample2/
├── phylogenetics/             # Phylogenetic analysis outputs
│   ├── alignment.phy          # PHYLIP format alignment
│   ├── alignment.nex          # NEXUS format alignment
│   └── raxml/                 # RAxML tree files
├── multiqc/                   # MultiQC aggregated report
│   ├── multiqc_report.html
│   └── multiqc_data/
└── pipeline_info/             # Execution reports and traces
```

## RAxML Output

The pipeline runs RAxML with:
- Model: GTRGAMMA
- Bootstraps: 100
- Output files: `RAxML_*` (including best tree)

## Format Conversions

### PHYLIP Format
Used for RAxML phylogenetic tree construction. Generated from filtered VCF files combining all samples.

### NEXUS Format
Generated separately for compatibility with SplitsTree and other phylogenetic tools.

## Resource Management

Resources are allocated based on process labels:

- **process_single**: 1 CPU, 2 GB RAM, 4h
- **process_low**: 2 CPUs, 4 GB RAM, 4h
- **process_medium**: 4 CPUs, 8 GB RAM, 8h
- **process_high**: 8 CPUs, 16 GB RAM, 16h

## Pipeline Reports

The pipeline automatically generates:

1. **MultiQC Report**: Aggregated QC metrics from all steps
2. **Execution Report**: Runtime statistics and resource usage
3. **Timeline**: Visual execution timeline
4. **DAG**: Directed acyclic graph of workflow
5. **Trace**: Detailed process execution trace

## Troubleshooting

### Common Issues

**Issue**: Samplesheet validation fails
- **Solution**: Ensure CSV format is correct with headers: `sample_id,read1,read2`

**Issue**: Memory errors
- **Solution**: Increase `--max_memory` parameter or reduce parallel tasks

**Issue**: Reference genome not indexed
- **Solution**: Ensure FASTA file is accessible; indexing is automatic

## Citation

If you use this pipeline, please cite:

- Nextflow: doi:10.1038/nbt.3820
- FastQC: https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
- Trimmomatic: doi:10.1093/bioinformatics/btu170
- BWA: doi:10.1093/bioinformatics/btp324
- Samtools: doi:10.1093/bioinformatics/btp352
- BCFtools: doi:10.1093/gigascience/giab008
- RAxML: doi:10.1093/bioinformatics/btu033
- MultiQC: doi:10.1093/bioinformatics/btw354

## License

This pipeline is distributed under the MIT License.

## Contact

For questions or issues, please open an issue on the repository.
