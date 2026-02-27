# Variant Calling and Phylogenetic Analysis Pipeline

A comprehensive Nextflow pipeline for joint variant calling from paired-end sequencing reads and downstream phylogenetic/population structure analysis.

## Pipeline Overview

This pipeline performs the following steps:

1.  **Quality Control (Raw)** - FastQC on raw reads.
2.  **Adapter Trimming** - Trimmomatic with specified parameters.
3.  **Quality Control (Trimmed)** - FastQC on trimmed reads.
4.  **Reference Indexing** - BWA index and Samtools faidx.
5.  **Read Alignment** - BWA-MEM with read group information.
6.  **BAM Processing** - Convert SAM to BAM, sort, remove duplicates, and index.
7.  **Alignment Statistics** - Samtools stats.
8.  **Joint Variant Calling** - BCFtools mpileup and call (jointly across all samples).
9.  **Variant Filtering** - Filter SNPs by quality criteria (QUAL>=20, DP>=10, MQ>=30).
10. **Phylogenetic Analysis**:
    *   Convert VCF to PHYLIP and NEXUS formats.
    *   RAxML tree construction (GTRGAMMA, 100 bootstraps).
    *   Optional SANS splits analysis.
11. **Population Structure (Optional)**:
    *   **PCA**: Ade4-based PCA analysis from SNP matrix.
    *   **Admixture**: ANGSD/NGSadmix analysis for specified K values.
12. **Reporting** - MultiQC aggregated quality control report.

## Requirements

### Software Dependencies

- Nextflow (>= 23.04.0)
- FastQC
- Trimmomatic
- BWA
- Samtools
- BCFtools
- RAxML
- ANGSD / NGSadmix
- R (with `ade4` package)
- Python 3

## Quick Start

### 1. Prepare Input Files

A `samplesheet.csv` is required with headers: `sample_id,read1,read2`.
A helper script or manual creation can be used to point to your FASTQ files.

### 2. Run the Pipeline

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --fasta ref/GCA_030518555.1_ASM3051855v1_genomic.fna \
    --adapters TruSeq3-PE.fa \
    --outdir results
```

### 3. Run with Optional Analyses

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --fasta ref/reference.fna \
    --run_pca true \
    --run_ngsadmix true --ngsadmix_k 3
```

## Parameters

### Required

| Parameter | Description |
|-----------|-------------|
| `--input` | Path to samplesheet CSV file |
| `--fasta` | Path to reference genome FASTA file |

### Optional Analysis Flags

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--run_pca` | `false` | Run Ade4 PCA analysis |
| `--run_ngsadmix` | `false` | Run ANGSD/NGSadmix analysis |
| `--run_sans` | `false` | Run SANS splits analysis |
| `--genome_list` | `null` | Required if `--run_sans` is true |

### Optional Tool Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--adapters` | `null` | Path to adapter sequences for Trimmomatic |
| `--ngsadmix_k` | `2` | Number of clusters (K) for NGSadmix |
| `--pca_center` | `true` | Center data for PCA |
| `--pca_scale` | `false` | Scale data for PCA |

## Variant Filtering Criteria

Variants are filtered using BCFtools with the following criteria:
- **Type**: SNPs only
- **QUAL**: ≥ 20
- **DP** (Total Depth): ≥ 10
- **MQ** (Mapping Quality): ≥ 30

## Output Structure

```
results/
├── fastqc/            # FastQC reports (raw and trimmed)
├── trimmomatic/       # Trimmed reads and logs
├── samtools/          # BAM files, indices, and stats
├── variants/          # Joint VCF (raw and filtered)
├── phylogenetics/     # PHYLIP, NEXUS, RAxML, and SANS results
├── pca/               # PCA matrix, plots, and RDS objects
├── angsd/             # Beagle files for admixture
├── ngsadmix/          # NGSadmix Q-plots and logs
├── multiqc/           # MultiQC aggregated report
└── pipeline_info/     # Execution reports and traces
```

## License

This pipeline is distributed under the MIT License.
