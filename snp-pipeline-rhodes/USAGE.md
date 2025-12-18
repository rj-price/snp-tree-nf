# Quick Start Guide

## Minimal Example

```bash
# 1. Prepare your sample sheet
cat > samples.csv << EOF
sample_id,read1,read2
sample1,/path/to/sample1_R1.fastq.gz,/path/to/sample1_R2.fastq.gz
sample2,/path/to/sample2_R1.fastq.gz,/path/to/sample2_R2.fastq.gz
EOF

# 2. Run the pipeline
nextflow run main.nf \
    --input samples.csv \
    --reference /path/to/Af293.fasta \
    -profile docker
```

## Complete Example with All Parameters

```bash
nextflow run main.nf \
    --input samples.csv \
    --reference reference/Af293.fasta \
    --reference_fai reference/Af293.fasta.fai \
    --reference_dict reference/Af293.dict \
    --repeat_mask reference/Af293_repeats.bed \
    --outdir results \
    --min_depth 10 \
    --min_mapping_quality 40.0 \
    --min_qual_by_depth 2.0 \
    --max_fisher_strand 60.0 \
    --min_ab_hom 0.9 \
    --min_genotype_quality 50 \
    --raxml_model GTRCAT \
    --raxml_bootstraps 1000 \
    --max_cpus 16 \
    --max_memory 128.GB \
    -profile docker \
    -resume
```

## Preparing Reference Files

### Create BWA index
```bash
bwa index reference/Af293.fasta
```

### Create FASTA index
```bash
samtools faidx reference/Af293.fasta
```

### Create sequence dictionary
```bash
gatk CreateSequenceDictionary \
    -R reference/Af293.fasta \
    -O reference/Af293.dict
```

### Generate repeat mask (optional)
```bash
RepeatMasker -species fungi \
    -pa 4 \
    -dir reference/ \
    reference/Af293.fasta

# Convert RepeatMasker output to BED format
# (custom script may be needed)
```

## Common Use Cases

### 1. Quick QC and alignment only
Comment out variant calling steps in `main.nf` or stop after alignment

### 2. Resume failed pipeline
```bash
nextflow run main.nf -resume --input samples.csv --reference ref.fasta -profile docker
```

### 3. Run on HPC with Slurm
Create a custom profile in `nextflow.config`:
```groovy
profiles {
    slurm {
        process.executor = 'slurm'
        process.queue = 'normal'
    }
}
```

Then run:
```bash
nextflow run main.nf -profile slurm,singularity --input samples.csv --reference ref.fasta
```

### 4. Adjust resource limits
```bash
nextflow run main.nf \
    --max_cpus 32 \
    --max_memory 256.GB \
    --max_time 48.h \
    ...
```

## Output Files Explained

### Key Output Files

1. **Alignments**: `results/alignments/*.sorted.bam`
   - Sorted BAM files ready for downstream analysis

2. **Variants**: `results/variants/filtered/*.filtered.vcf.gz`
   - High-quality filtered variants per sample

3. **Phylogeny**: `results/phylogenetics/RAxML_bipartitions.phylogeny`
   - Final phylogenetic tree with bootstrap support

4. **SNP Matrix**: `results/phylogenetics/snp_matrix.phylip`
   - Presence/absence matrix for all SNPs

5. **Reports**: `results/pipeline_info/execution_report.html`
   - Interactive execution report

## Troubleshooting Tips

### Issue: Out of memory errors
**Solution**: Increase memory allocation
```bash
nextflow run main.nf --max_memory 256.GB ...
```

### Issue: Process fails intermittently
**Solution**: The pipeline automatically retries failed processes. Check logs:
```bash
cat work/[hash]/.command.log
```

### Issue: Missing reference index files
**Solution**: Generate all required reference files (see "Preparing Reference Files" above)

## Advanced Configuration

### Custom container images
Edit `nextflow.config` and change container paths:
```groovy
process {
    withName: 'BWA_MEM' {
        container = 'my-registry/bwa:custom'
    }
}
```

### Adjust process resources
In `nextflow.config`:
```groovy
process {
    withName: 'GATK_HAPLOTYPECALLER' {
        cpus = 24
        memory = 128.GB
        time = 48.h
    }
}
```

### Enable Fusion file system (Seqera Platform)
In `nextflow.config`:
```groovy
fusion {
    enabled = true
}

wave {
    enabled = true
}
```

## Performance Optimization

1. **Use `-resume`** to skip completed steps when re-running
2. **Enable Wave containers** for faster container provisioning (Seqera Platform)
3. **Use local scratch space** for temporary files:
   ```groovy
   process.scratch = '/local/scratch'
   ```
4. **Parallel sample processing**: The pipeline automatically processes all samples in parallel

## Pipeline Metrics

After completion, check:
- `results/pipeline_info/execution_report.html` - Resource usage and timing
- `results/pipeline_info/execution_timeline.html` - Visual timeline of process execution
- `results/pipeline_info/pipeline_dag.svg` - Visual workflow diagram

## Next Steps After Pipeline Completion

1. **Visualize phylogenetic tree**: Use FigTree, iTOL, or R/ggtree
   ```R
   library(ape)
   tree <- read.tree("results/phylogenetics/RAxML_bipartitions.phylogeny")
   plot(tree)
   ```

2. **Analyze variant patterns**: Use VCF tools
   ```bash
   bcftools stats results/variants/filtered/sample1.filtered.vcf.gz
   ```

3. **Generate MultiQC report**: Aggregate all QC metrics
   ```bash
   multiqc results/
   ```
