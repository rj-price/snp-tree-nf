#!/bin/bash
#SBATCH --job-name=snp_pipeline
#SBATCH --output=pipeline_%j.out
#SBATCH --error=pipeline_%j.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=20G
#SBATCH --partition=long

# Usage: sbatch illumina_pipeline.sh <reads_folder> <reference_genome>
# Example: sbatch illumina_pipeline.sh ./raw_reads ./reference/genome.fasta

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# =============================================================================
# PARAMETERS
# =============================================================================

# DIRECTORIES (Please edit these)
READS_FOLDER="/mnt/shared/scratch/jnprice/private/seqera_ai/roqueforti_test_data"      # Directory containing paired-end fastq files
REFERENCE="/mnt/shared/scratch/jnprice/private/seqera_ai/roqueforti_test_data/ref/GCA_030518555.1_ASM3051855v1_genomic.fna" # Path to reference genome fasta

# THREADS
THREADS=$SLURM_CPUS_PER_TASK

# ADAPTER FILE (For Trimmomatic)
ADAPTERS="/mnt/shared/scratch/jnprice/private/seqera_ai/manual-snp-test/TruSeq3-PE.fa"

# Create output directories
WORK_DIR=$(pwd)
QC_RAW="${WORK_DIR}/01_qc_raw"
TRIMMED="${WORK_DIR}/02_trimmed"
QC_TRIMMED="${WORK_DIR}/03_qc_trimmed"
ALIGNED="${WORK_DIR}/04_aligned"
VARIANTS="${WORK_DIR}/05_variants"
PHYLO="${WORK_DIR}/06_phylogeny"

mkdir -p ${QC_RAW} ${TRIMMED} ${QC_TRIMMED} ${ALIGNED} ${VARIANTS} ${PHYLO}

# =============================================================================
# LOAD MODULES (adjust for your cluster)
# =============================================================================

# module load fastqc/0.11.9
# module load multiqc/1.12
# module load trimmomatic/0.39
# module load bwa/0.7.17
# module load samtools/1.15
# module load bcftools/1.15
# module load vcftools/0.1.16
# module load splitstree/4.14.8

# ACTIVATE CONDA ENVIRONMENT
source activate snp_pipeline

# =============================================================================
# STEP 1: INITIAL QUALITY CONTROL
# =============================================================================

echo "==================================================================="
echo "STEP 1: Running FastQC on raw reads"
echo "==================================================================="

fastqc -t ${THREADS} -o ${QC_RAW} ${READS_FOLDER}/*.fastq.gz

#echo "Running MultiQC on raw reads..."
#multiqc ${QC_RAW} -o ${QC_RAW} -n raw_reads_multiqc

# =============================================================================
# STEP 2: READ TRIMMING
# =============================================================================

echo "==================================================================="
echo "STEP 2: Trimming reads with Trimmomatic"
echo "==================================================================="

for R1 in ${READS_FOLDER}/*_1*.fastq.gz; do
    # Get sample name
    SAMPLE=$(basename ${R1} | sed 's/_1.*//')
    R2=${READS_FOLDER}/${SAMPLE}_2*.fastq.gz
    
    echo "Processing sample: ${SAMPLE}"
    
    trimmomatic PE -threads ${THREADS} \
        ${R1} ${R2} \
        ${TRIMMED}/${SAMPLE}_R1_paired.fastq.gz \
        ${TRIMMED}/${SAMPLE}_R1_unpaired.fastq.gz \
        ${TRIMMED}/${SAMPLE}_R2_paired.fastq.gz \
        ${TRIMMED}/${SAMPLE}_R2_unpaired.fastq.gz \
        ILLUMINACLIP:${ADAPTERS}:2:30:10:2:keepBothReads \
        LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
done

# =============================================================================
# STEP 3: POST-TRIMMING QUALITY CONTROL
# =============================================================================

echo "==================================================================="
echo "STEP 3: Running FastQC on trimmed reads"
echo "==================================================================="

fastqc -t ${THREADS} -o ${QC_TRIMMED} ${TRIMMED}/*_paired.fastq.gz

#echo "Running MultiQC on trimmed reads..."
#multiqc ${QC_TRIMMED} -o ${QC_TRIMMED} -n trimmed_reads_multiqc

# =============================================================================
# STEP 4: INDEX REFERENCE GENOME (if needed)
# =============================================================================

echo "==================================================================="
echo "STEP 4: Checking/Creating BWA index for reference genome"
echo "==================================================================="

if [ ! -f "${REFERENCE}.bwt" ]; then
    echo "BWA index not found. Indexing reference genome..."
    bwa index ${REFERENCE}
else
    echo "BWA index already exists. Skipping indexing."
fi

# Also create .fai index for samtools
if [ ! -f "${REFERENCE}.fai" ]; then
    echo "Creating samtools faidx index..."
    samtools faidx ${REFERENCE}
fi

# =============================================================================
# STEP 5: ALIGNMENT WITH BWA
# =============================================================================

echo "==================================================================="
echo "STEP 5: Aligning reads to reference genome with BWA"
echo "==================================================================="

BAM_LIST="${ALIGNED}/bam_files.list"
> ${BAM_LIST}  # Clear the file

for R1 in ${TRIMMED}/*_R1_paired.fastq.gz; do
    SAMPLE=$(basename ${R1} | sed 's/_R1_paired.fastq.gz//')
    R2=${TRIMMED}/${SAMPLE}_R2_paired.fastq.gz
    
    echo "Aligning sample: ${SAMPLE}"
    
    # Align with BWA MEM
    bwa mem -t ${THREADS} -R "@RG\tID:${SAMPLE}\tSM:${SAMPLE}\tPL:ILLUMINA" \
        ${REFERENCE} ${R1} ${R2} | \
        samtools view -@ ${THREADS} -bS - | \
        samtools sort -@ ${THREADS} -o ${ALIGNED}/${SAMPLE}.sorted.bam -
    
    # Index BAM file
    samtools index ${ALIGNED}/${SAMPLE}.sorted.bam
    
    # Add to BAM list
    echo "${ALIGNED}/${SAMPLE}.sorted.bam" >> ${BAM_LIST}
    
    # Generate alignment stats
    samtools flagstat ${ALIGNED}/${SAMPLE}.sorted.bam > ${ALIGNED}/${SAMPLE}.flagstat.txt
done

# =============================================================================
# STEP 6: VARIANT CALLING
# =============================================================================

echo "==================================================================="
echo "STEP 6: Calling variants with bcftools"
echo "==================================================================="

# Call variants using bcftools mpileup and call
echo "Running bcftools mpileup..."
bcftools mpileup -Ou -f ${REFERENCE} --bam-list ${BAM_LIST} \
    --threads ${THREADS} -a FORMAT/AD,FORMAT/DP | \
    bcftools call -mv -Oz --threads ${THREADS} \
    -o ${VARIANTS}/raw_variants.vcf.gz

# Index VCF
bcftools index ${VARIANTS}/raw_variants.vcf.gz

echo "Total variants called:"
bcftools view -H ${VARIANTS}/raw_variants.vcf.gz | wc -l

# =============================================================================
# STEP 7: VARIANT FILTERING
# =============================================================================

echo "==================================================================="
echo "STEP 7: Filtering variants"
echo "==================================================================="

# Filter variants (adjust thresholds as needed)
bcftools filter -Oz -o ${VARIANTS}/filtered_variants.vcf.gz \
    -i 'QUAL>=20 && DP>=10 && MQ>=30' \
    ${VARIANTS}/raw_variants.vcf.gz

bcftools index ${VARIANTS}/filtered_variants.vcf.gz

echo "Variants after filtering:"
bcftools view -H ${VARIANTS}/filtered_variants.vcf.gz | wc -l

# Extract only SNPs
bcftools view -v snps -Oz -o ${VARIANTS}/snps_only.vcf.gz \
    ${VARIANTS}/filtered_variants.vcf.gz

bcftools index ${VARIANTS}/snps_only.vcf.gz

echo "SNPs only:"
bcftools view -H ${VARIANTS}/snps_only.vcf.gz | wc -l

# =============================================================================
# STEP 8: PREPARE DATA FOR SPLITSTREE
# =============================================================================

echo "==================================================================="
echo "STEP 8: Converting VCF to NEXUS format for SplitsTree"
echo "==================================================================="

# Convert VCF to PHYLIP format using vcf-to-tab
vcf-to-tab < ${VARIANTS}/snps_only.vcf.gz > ${PHYLO}/snps.tab

# Create a simple script to convert to NEXUS format
python3 << 'EOF'
import sys
import gzip

# Read VCF and create NEXUS format
vcf_file = "05_variants/snps_only.vcf.gz"
nexus_file = "06_phylogeny/snps.nex"

samples = []
sequences = {}

with gzip.open(vcf_file, 'rt') as f:
    for line in f:
        if line.startswith('##'):
            continue
        if line.startswith('#CHROM'):
            samples = line.strip().split('\t')[9:]
            for sample in samples:
                sequences[sample] = []
            continue
        
        fields = line.strip().split('\t')
        ref = fields[3]
        alt = fields[4]
        
        genotypes = fields[9:]
        for i, gt_info in enumerate(genotypes):
            gt = gt_info.split(':')[0]
            if gt == '0/0' or gt == '0|0':
                sequences[samples[i]].append(ref)
            elif gt == '1/1' or gt == '1|1':
                sequences[samples[i]].append(alt)
            elif gt in ['0/1', '0|1', '1/0', '1|0']:
                sequences[samples[i]].append('N')  # Heterozygous
            else:
                sequences[samples[i]].append('N')  # Missing

# Write NEXUS format
with open(nexus_file, 'w') as out:
    out.write("#NEXUS\n\n")
    out.write("BEGIN DATA;\n")
    out.write(f"DIMENSIONS NTAX={len(samples)} NCHAR={len(sequences[samples[0]])};\n")
    out.write("FORMAT DATATYPE=DNA MISSING=N GAP=-;\n")
    out.write("MATRIX\n")
    
    for sample in samples:
        seq = ''.join(sequences[sample])
        out.write(f"{sample}\t{seq}\n")
    
    out.write(";\nEND;\n")

print(f"NEXUS file created: {nexus_file}")
print(f"Number of samples: {len(samples)}")
print(f"Number of SNPs: {len(sequences[samples[0]])}")
EOF

# =============================================================================
# STEP 9: GENERATE NEIGHBOUR NET WITH SPLITSTREE
# =============================================================================

echo "==================================================================="
echo "STEP 9: Generating Neighbour Net with SplitsTree"
echo "==================================================================="

# Run SplitsTree (command line version)
# Note: Adjust the command based on your SplitsTree installation
splitstree -g -i ${PHYLO}/snps.nex -o ${PHYLO}/neighbour_net.nex -x "EXECUTE FILE=${PHYLO}/snps.nex; NeighborNet; SAVE FILE=${PHYLO}/neighbour_net.nex REPLACE=yes; QUIT;"

echo "SplitsTree analysis complete. Output saved to ${PHYLO}/neighbour_net.nex"

# =============================================================================
# PIPELINE COMPLETE
# =============================================================================

echo "==================================================================="
echo "PIPELINE COMPLETED SUCCESSFULLY!"
echo "==================================================================="
echo "Results are organized in the following directories:"
echo "  - Raw QC:      ${QC_RAW}"
echo "  - Trimmed:     ${TRIMMED}"
echo "  - Trimmed QC:  ${QC_TRIMMED}"
echo "  - Aligned:     ${ALIGNED}"
echo "  - Variants:    ${VARIANTS}"
echo "  - Phylogeny:   ${PHYLO}"
echo "==================================================================="