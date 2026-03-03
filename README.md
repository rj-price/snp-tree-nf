# SNP-Tree-NF: Variant Calling and Phylogenetic Analysis Pipeline

A comprehensive Nextflow pipeline for joint variant calling from paired-end Illumina sequencing reads and downstream phylogenetic and population structure analysis.

## Pipeline Overview

This pipeline automates the entire process from raw FASTQ files to phylogenetic trees and population structure plots:

1.  **Quality Control** - FastQC on raw and trimmed reads.
2.  **Adapter Trimming** - Trimmomatic for adapter removal and quality filtering.
3.  **Read Alignment** - BWA-MEM alignment against a reference genome.
4.  **BAM Processing** - SAM to BAM conversion, sorting, duplicate removal (Samtools rmdup), and indexing.
5.  **Alignment Statistics** - Samtools stats for coverage and mapping quality metrics.
6.  **Joint Variant Calling** - BCFtools mpileup and call (jointly across all samples for consistency).
7.  **Variant Filtering** - SNP-specific filtering (QUAL>=20, DP>=10, MQ>=30).
8.  **Phylogenetic Analysis**:
    *   Conversion of VCF to PHYLIP and NEXUS formats.
    *   **RAxML** Maximum Likelihood tree construction (GTRGAMMA model, 100 bootstraps).
9.  **Population Structure (Optional)**:
    *   **PCAngsd** analysis for likelihood-based PCA and Admixture proportions.
    *   Automated plotting of Admixture barplots and PCA scatter plots.
10. **Reporting** - Aggregate MultiQC report for all QC metrics.

## Requirements

*   **Nextflow** (>= 23.04.0)
*   **Singularity**, **Apptainer**, or **Docker** (recommended for reproducibility)
*   Alternatively, a **Conda** environment (though containers are preferred)

## Quick Start

### 1. Prepare Input Files

Create a `samplesheet.csv` with the following headers:
```csv
sample_id,read1,read2
Sample1,data/Sample1_R1.fastq.gz,data/Sample1_R2.fastq.gz
Sample2,data/Sample2_R1.fastq.gz,data/Sample2_R2.fastq.gz
```

### 2. Run the Pipeline

```bash
nextflow run main.nf \
    -profile singularity \
    --input samplesheet.csv \
    --fasta ref/reference.fna \
    --adapters TruSeq3-PE.fa \
    --outdir results
```

## Parameters

### Required Parameters

| Parameter | Description |
|-----------|-------------|
| `--input` | Path to samplesheet CSV file |
| `--fasta` | Path to reference genome FASTA file |

### Optional Analysis Flags

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--run_admixture` | `false` | Run PCAngsd for PCA and Admixture analysis |

### Optional Tool Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--adapters` | `null` | Path to adapter sequences for Trimmomatic |
| `--outdir` | `./results` | Directory to save results |

## Execution Profiles

*   `-profile singularity`: Use Singularity/Apptainer containers (recommended for HPC).
*   `-profile docker`: Use Docker containers.
*   `-profile slurm`: Submit jobs to a Slurm workload manager.
*   `-profile test`: Run a minimal test with default settings.

Example for HPC with Slurm:
```bash
nextflow run main.nf -profile slurm,singularity --input samplesheet.csv --fasta ref/ref.fna
```

## Variant Filtering Criteria

The pipeline applies stringent filters to ensure high-quality SNP calls:
*   **Type**: SNPs only (indels removed)
*   **QUAL**: ≥ 20 (99% base call accuracy)
*   **DP** (Total Depth): ≥ 10
*   **MQ** (Mapping Quality): ≥ 30

## Output Structure

```
results/
├── fastqc/            # FastQC reports (raw and trimmed)
├── trimmomatic/       # Trimmed reads and logs
├── samtools/          # BAM files, indices, and stats
├── variants/          # Joint VCF (raw and filtered)
├── phylogenetics/     # PHYLIP, NEXUS, and RAxML results
├── angsd/             # Beagle likelihood files
├── pcangsd/           # PCAngsd raw output (cov, admix)
│   └── plots/         # PNG visualizations of PCA and Admixture
├── multiqc/           # Aggregated QC report
└── pipeline_info/     # Nextflow execution reports and traces
```

## Notes

*   **RAxML Species Limit**: RAxML requires at least 4 species to construct a tree. If your samplesheet has fewer than 4 samples, the RAxML step will be skipped gracefully with a warning.
*   **PCAngsd**: This tool is optimized for low-to-medium coverage data as it uses genotype likelihoods rather than hard-called genotypes.

## License

This pipeline is distributed under the MIT License.
