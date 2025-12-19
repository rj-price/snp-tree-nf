# Pipeline Usage Guide

## Basic Usage

### Minimal Command

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --fasta genome.fa
```

### Full Command with Options

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --fasta genome.fa \
    --adapters adapters.fa \
    --outdir my_results \
    --max_cpus 16 \
    --max_memory 32.GB
```

## Input Preparation

### 1. Create Samplesheet

The samplesheet must be a CSV file with three columns:

```csv
sample_id,read1,read2
SRR001,data/SRR001_1.fastq.gz,data/SRR001_2.fastq.gz
SRR002,data/SRR002_1.fastq.gz,data/SRR002_2.fastq.gz
SRR003,data/SRR003_1.fastq.gz,data/SRR003_2.fastq.gz
```

**Requirements**:
- Header line must be: `sample_id,read1,read2`
- Sample IDs must be unique
- All files must exist and be accessible
- Paths can be absolute or relative

### 2. Prepare Reference Genome

Provide a FASTA file for your reference genome:

```bash
--fasta /path/to/reference_genome.fasta
```

The pipeline will automatically create:
- BWA index files
- Samtools faidx index

### 3. (Optional) Adapter File

For Trimmomatic adapter trimming, provide an adapter sequences file:

```bash
--adapters /path/to/adapters/TruSeq3-PE.fa
```

Common adapter files:
- TruSeq3-PE.fa (Illumina TruSeq3 paired-end)
- TruSeq2-PE.fa (Illumina TruSeq2 paired-end)
- NexteraPE-PE.fa (Illumina Nextera paired-end)

## Running with Different Profiles

### Local Execution

```bash
nextflow run main.nf --input samplesheet.csv --fasta genome.fa
```

### With Docker

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --fasta genome.fa \
    -profile docker
```

### With Singularity

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --fasta genome.fa \
    -profile singularity
```

### On HPC Cluster (SLURM example)

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --fasta genome.fa \
    -profile slurm
```

## Understanding the Output

### Key Output Files

#### 1. MultiQC Report
**Location**: `results/multiqc/multiqc_report.html`

Open in browser for comprehensive quality metrics including:
- FastQC results (raw and trimmed)
- Trimming statistics
- Alignment statistics
- Overall pipeline summary

#### 2. Filtered Variants
**Location**: `results/variants/[sample_id]/[sample_id].filtered.vcf.gz`

High-quality SNP calls for each sample with filtering criteria:
- QUAL ≥ 20
- DP ≥ 10
- MQ ≥ 30

#### 3. Phylogenetic Files
**Location**: `results/phylogenetics/`

- `alignment.phy` - PHYLIP format for RAxML
- `alignment.nex` - NEXUS format for SplitsTree
- `raxml/RAxML_bestTree.tree` - Best maximum likelihood tree

#### 4. Alignment Files
**Location**: `results/samtools/[sample_id]/`

- `[sample_id].sorted.bam` - Sorted BAM file
- `[sample_id].sorted.bam.bai` - BAM index
- `[sample_id].stats` - Alignment statistics

## Monitoring Pipeline Execution

### Real-time Progress

Nextflow provides real-time progress updates:

```
executor >  local (45)
[3a/f9b2c4] process > FASTQC_RAW (sample1)      [100%] 3 of 3 ✔
[7e/d43a21] process > TRIMMOMATIC (sample1)     [100%] 3 of 3 ✔
[2b/8c1f92] process > BWA_MEM (sample1)         [ 66%] 2 of 3
```

### Execution Reports

After completion, check:

1. **Timeline**: `results/pipeline_info/execution_timeline.html`
   - Visual timeline of all processes
   - Identify bottlenecks

2. **Report**: `results/pipeline_info/execution_report.html`
   - Resource usage statistics
   - Success/failure rates

3. **Trace**: `results/pipeline_info/execution_trace.txt`
   - Detailed process metrics
   - CPU, memory, and I/O statistics

## Advanced Options

### Resume Failed Runs

If the pipeline fails or is interrupted:

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --fasta genome.fa \
    -resume
```

### Custom Resource Allocation

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --fasta genome.fa \
    --max_cpus 32 \
    --max_memory 128.GB \
    --max_time 72.h
```

### Change Output Directory

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --fasta genome.fa \
    --outdir /scratch/user/variant_analysis
```

## Interpreting Results

### Quality Control

1. Check MultiQC report first
2. Verify per-base sequence quality > 30
3. Check adapter content is removed
4. Verify alignment rates > 90%

### Variant Analysis

1. Review number of variants per sample
2. Check variant quality distributions
3. Examine depth of coverage
4. Validate filtering reduced low-quality calls

### Phylogenetic Analysis

1. Open RAxML best tree in tree viewer (e.g., FigTree, iTOL)
2. Check bootstrap support values
3. Verify expected sample relationships
4. Use NEXUS file for network analysis in SplitsTree

## Example Workflow

### Complete Analysis

```bash
# 1. Create samplesheet
cat > samplesheet.csv << EOF
sample_id,read1,read2
ecoli1,reads/ecoli1_R1.fq.gz,reads/ecoli1_R2.fq.gz
ecoli2,reads/ecoli2_R1.fq.gz,reads/ecoli2_R2.fq.gz
ecoli3,reads/ecoli3_R1.fq.gz,reads/ecoli3_R2.fq.gz
EOF

# 2. Run pipeline
nextflow run main.nf \
    --input samplesheet.csv \
    --fasta refs/ecoli_K12.fasta \
    --adapters adapters/TruSeq3-PE.fa \
    --outdir results_ecoli \
    --max_cpus 8

# 3. Check results
firefox results_ecoli/multiqc/multiqc_report.html
figtree results_ecoli/phylogenetics/raxml/RAxML_bestTree.tree
```

## Troubleshooting

### Pipeline won't start

**Check**:
- Nextflow is installed: `nextflow -version`
- Input files exist: `ls -l samplesheet.csv`
- Reference genome exists: `ls -l genome.fa`

### Out of memory errors

**Solutions**:
1. Increase `--max_memory`
2. Reduce number of parallel processes
3. Check per-process memory in `conf/base.config`

### Processes fail intermittently

**Solutions**:
1. Use `-resume` to restart from last checkpoint
2. Check system resources with `top` or `htop`
3. Review `.nextflow.log` for detailed errors

### Variants not found

**Check**:
- Reference genome matches sequencing data
- Read quality is sufficient
- Sequencing depth is adequate (>10x)
- Variant filtering criteria aren't too strict

## Tips for Best Results

1. **Quality First**: Review FastQC reports before proceeding
2. **Adequate Depth**: Ensure >20x coverage for reliable variant calling
3. **Proper Reference**: Use appropriate reference genome for your organism
4. **Resource Planning**: Allocate sufficient memory for alignment steps
5. **Resume Feature**: Always use `-resume` when re-running
6. **Check Logs**: Review MultiQC and execution reports thoroughly

## Getting Help

If you encounter issues:

1. Check the error message in terminal
2. Review `.nextflow.log` file
3. Check process-specific logs in `work/` directory
4. Verify input file formats
5. Ensure all dependencies are installed

## Next Steps

After successful run:

1. **Visualize tree**: Use FigTree, iTOL, or R packages
2. **Further filtering**: Apply additional filters to VCF files
3. **Annotation**: Annotate variants with SnpEff or VEP
4. **Population analysis**: Use filtered VCFs for population genomics
5. **Publication**: Include MultiQC report and tree figures
