# Quick Start Guide

## 🚀 Run the Pipeline in 3 Steps

### Step 1: Prepare Input Samplesheet

Create a CSV file with your samples:

```bash
cat > my_samples.csv << EOF
sample_id,read1,read2
sample1,reads/sample1_R1.fq.gz,reads/sample1_R2.fq.gz
sample2,reads/sample2_R1.fq.gz,reads/sample2_R2.fq.gz
sample3,reads/sample3_R1.fq.gz,reads/sample3_R2.fq.gz
EOF
```

### Step 2: Run the Pipeline

```bash
nextflow run main.nf \
    --input my_samples.csv \
    --fasta reference_genome.fa \
    --outdir results
```

### Step 3: View Results

```bash
# Open MultiQC report
firefox results/multiqc/multiqc_report.html

# View phylogenetic tree
figtree results/phylogenetics/raxml/RAxML_bestTree.tree
```

## 📋 Essential Commands

### Basic Run
```bash
nextflow run main.nf --input samples.csv --fasta genome.fa
```

### With Adapter Trimming
```bash
nextflow run main.nf \
    --input samples.csv \
    --fasta genome.fa \
    --adapters TruSeq3-PE.fa
```

### Resume Failed Run
```bash
nextflow run main.nf --input samples.csv --fasta genome.fa -resume
```

### Custom Resources
```bash
nextflow run main.nf \
    --input samples.csv \
    --fasta genome.fa \
    --max_cpus 16 \
    --max_memory 64.GB
```

### Change Output Directory
```bash
nextflow run main.nf \
    --input samples.csv \
    --fasta genome.fa \
    --outdir my_results
```

## 📊 Key Output Files

| File | Location | Description |
|------|----------|-------------|
| **MultiQC Report** | `results/multiqc/multiqc_report.html` | Comprehensive QC summary |
| **Filtered VCFs** | `results/variants/[sample]/[sample].filtered.vcf.gz` | High-quality SNPs per sample |
| **Best Tree** | `results/phylogenetics/raxml/RAxML_bestTree.tree` | Maximum likelihood tree |
| **PHYLIP Alignment** | `results/phylogenetics/alignment.phy` | Multi-sample alignment |
| **NEXUS Alignment** | `results/phylogenetics/alignment.nex` | For SplitsTree |
| **BAM Files** | `results/samtools/[sample]/[sample].sorted.bam` | Sorted alignments |

## 🔍 Pipeline Overview

```
Input Reads → QC → Trim → QC → Align → BAM → Variants → Filter → Tree
                                  ↓              ↓
                              Stats          MultiQC
```

### What It Does:

1. ✅ **Quality Control** - FastQC on raw and trimmed reads
2. ✅ **Trimming** - Remove adapters and low-quality bases
3. ✅ **Alignment** - BWA-MEM with read groups
4. ✅ **BAM Processing** - Convert, sort, index, stats
5. ✅ **Variant Calling** - BCFtools (SNPs only)
6. ✅ **Filtering** - QUAL≥20, DP≥10, MQ≥30
7. ✅ **Phylogenetics** - RAxML tree with 100 bootstraps
8. ✅ **Reporting** - MultiQC aggregated report

## ⚙️ Default Settings

### Trimmomatic
- Window: 4:20
- Min Length: 36
- Head Crop: 10

### Variant Filter
- SNPs only
- Quality ≥ 20
- Depth ≥ 10
- Mapping Quality ≥ 30

### RAxML
- Model: GTRGAMMA
- Bootstraps: 100

### Resources
- CPUs: 16 max
- Memory: 128 GB max
- Time: 96 hours max

## 🆘 Troubleshooting

### Pipeline won't start?
```bash
# Check Nextflow installation
nextflow -version

# Check input files exist
ls -l my_samples.csv reference_genome.fa
```

### Out of memory?
```bash
# Increase memory allocation
nextflow run main.nf \
    --input samples.csv \
    --fasta genome.fa \
    --max_memory 32.GB
```

### Process failed?
```bash
# Resume from last checkpoint
nextflow run main.nf \
    --input samples.csv \
    --fasta genome.fa \
    -resume

# Check logs
cat .nextflow.log
```

### Samplesheet errors?
```bash
# Validate format (must have headers)
head -1 samples.csv
# Should show: sample_id,read1,read2

# Check for duplicates
cut -d',' -f1 samples.csv | sort | uniq -d
```

## 📚 Need More Help?

- **Detailed docs**: See `README.md`
- **Usage examples**: See `USAGE.md`
- **Technical details**: See `PIPELINE_SUMMARY.md`
- **Directory layout**: See `DIRECTORY_STRUCTURE.txt`

## ✨ Example Samplesheet

```csv
sample_id,read1,read2
ecoli_K12,data/K12_R1.fastq.gz,data/K12_R2.fastq.gz
ecoli_O157,data/O157_R1.fastq.gz,data/O157_R2.fastq.gz
ecoli_CFT073,data/CFT073_R1.fastq.gz,data/CFT073_R2.fastq.gz
```

## 🎯 Expected Runtime

For 3 bacterial genomes (~5M reads each):
- **FastQC**: ~10 minutes
- **Trimming**: ~15 minutes
- **Alignment**: ~30 minutes
- **Variant Calling**: ~20 minutes
- **RAxML**: ~60 minutes
- **Total**: ~2.5-3 hours

*Runtime varies based on:*
- Number of samples
- Read depth
- Genome size
- Available resources

## ✅ Success Indicators

Pipeline completed successfully if you see:

```
[✔] Pipeline completed at: [timestamp]
[✔] Execution status: OK
[✔] Duration: [time]
```

And these files exist:
- ✅ `results/multiqc/multiqc_report.html`
- ✅ `results/phylogenetics/raxml/RAxML_bestTree.tree`
- ✅ Filtered VCF for each sample

---

**Ready to start?** Run your first analysis now! 🚀

```bash
cd variant-phylo-pipeline
nextflow run main.nf --input assets/samplesheet.csv --fasta your_genome.fa
```
