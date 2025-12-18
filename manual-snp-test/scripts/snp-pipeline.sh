#!/bin/bash
#SBATCH --job-name=snp_pipeline
#SBATCH --output=logs/pipeline_%j.out
#SBATCH --error=logs/pipeline_%j.err
#SBATCH --cpus-per-task=8
#SBATCH --mem=20G
#SBATCH --partition=long

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# DIRECTORIES (Please edit these)
INPUT_DIR="/mnt/shared/scratch/jnprice/private/seqera_ai/roqueforti_test_data"      # Directory containing paired-end fastq files
REF_GENOME="/mnt/shared/scratch/jnprice/private/seqera_ai/roqueforti_test_data/ref/GCA_030518555.1_ASM3051855v1_genomic.fna" # Path to reference genome fasta
OUTPUT_DIR="/mnt/shared/scratch/jnprice/private/seqera_ai/manual-snp-test/pipeline_test_output"        # Base directory for results
SCRIPTS_DIR="/mnt/shared/scratch/jnprice/private/seqera_ai/manual-snp-test/scripts" # Directory containing helper scripts

# THREADS
THREADS=$SLURM_CPUS_PER_TASK

# ADAPTER FILE (For Trimmomatic)
ADAPTERS="/mnt/shared/scratch/jnprice/private/seqera_ai/manual-snp-test/TruSeq3-PE.fa"

# ACTIVATE CONDA ENVIRONMENT
source activate snp_pipeline

# Error handling: Stop script on error
set -e

# ==============================================================================
# SETUP
# ==============================================================================

# Create output subdirectories
mkdir -p logs
mkdir -p ${OUTPUT_DIR}/fastqc_pre
mkdir -p ${OUTPUT_DIR}/trimmed
mkdir -p ${OUTPUT_DIR}/fastqc_post
mkdir -p ${OUTPUT_DIR}/alignments
mkdir -p ${OUTPUT_DIR}/variants

echo "Starting Pipeline at $(date)"

# ==============================================================================
# STEP 1: INDEX REFERENCE GENOME
# ==============================================================================

# Check if BWA index exists (looks for .bwt file)
if [ ! -f "${REF_GENOME}.bwt" ]; then
    echo "BWA index not found. Indexing reference genome..."
    bwa index ${REF_GENOME}
else
    echo "Reference genome already indexed with BWA."
fi

# Check if Samtools index exists (looks for .fai file)
if [ ! -f "${REF_GENOME}.fai" ]; then
    echo "Samtools index not found. Indexing reference genome..."
    samtools faidx ${REF_GENOME}
else
    echo "Reference genome already indexed with Samtools."
fi

# ==============================================================================
# STEP 2 & 3: QC, TRIMMING, ALIGNMENT LOOP
# ==============================================================================

echo "Processing samples..."

# Loop through all R1 files in the input directory
for R1_FILE in ${INPUT_DIR}/*_1.fastq; do
    
    # Define filenames
    FILENAME=$(basename ${R1_FILE})
    SAMPLE_NAME=${FILENAME%%_1.fastq} # Extract sample ID
    R2_FILE=${R1_FILE/_1/_2}            # Infer R2 filename

    echo "Processing Sample: ${SAMPLE_NAME}"

    # --- A. Pre-Trim FastQC ---
    fastqc -t ${THREADS} -o ${OUTPUT_DIR}/fastqc_pre ${R1_FILE} ${R2_FILE}

    # --- B. Trimming (Trimmomatic) ---
    # Output filenames for trimming
    R1_PAIRED="${OUTPUT_DIR}/trimmed/${SAMPLE_NAME}_R1_paired.fq.gz"
    R1_UNPAIRED="${OUTPUT_DIR}/trimmed/${SAMPLE_NAME}_R1_unpaired.fq.gz"
    R2_PAIRED="${OUTPUT_DIR}/trimmed/${SAMPLE_NAME}_R2_paired.fq.gz"
    R2_UNPAIRED="${OUTPUT_DIR}/trimmed/${SAMPLE_NAME}_R2_unpaired.fq.gz"

    trimmomatic PE -threads ${THREADS} \
        ${R1_FILE} ${R2_FILE} \
        ${R1_PAIRED} ${R1_UNPAIRED} \
        ${R2_PAIRED} ${R2_UNPAIRED} \
        ILLUMINACLIP:${ADAPTERS}:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 HEADCROP:10 MINLEN:36

    # --- C. Post-Trim FastQC ---
    fastqc -t ${THREADS} -o ${OUTPUT_DIR}/fastqc_post ${R1_PAIRED} ${R2_PAIRED}

    # --- D. Alignment (BWA MEM) ---
    # Pipe: BWA -> Samtools View (BAM) -> Samtools Sort
    SORTED_BAM="${OUTPUT_DIR}/alignments/${SAMPLE_NAME}.sorted.bam"

    echo "Aligning ${SAMPLE_NAME}..."
    bwa mem -t ${THREADS} ${REF_GENOME} ${R1_PAIRED} ${R2_PAIRED} | \
    samtools view -@ ${THREADS} -bS - | \
    samtools sort -@ ${THREADS} -o ${SORTED_BAM} -

    # Index the BAM file
    samtools index ${SORTED_BAM}

done

# ==============================================================================
# STEP 4: MULTIQC AGGREGATION
# ==============================================================================

#echo "Running MultiQC..."
# Run on both pre and post QC directories
#multiqc ${OUTPUT_DIR}/fastqc_pre ${OUTPUT_DIR}/fastqc_post -o ${OUTPUT_DIR}/multiqc_report

# ==============================================================================
# STEP 5: VARIANT CALLING (BCFTOOLS)
# ==============================================================================

echo "Calling Variants..."

# Create a list of all BAM files
find ${OUTPUT_DIR}/alignments -name "*.sorted.bam" > ${OUTPUT_DIR}/bam_list.txt

# Run mpileup and call variants
bcftools mpileup --threads ${THREADS} -Ou -m 10 -d 1000 -f ${REF_GENOME} -b ${OUTPUT_DIR}/bam_list.txt | \
    bcftools call --threads ${THREADS} -cv --ploidy 1 -o ${OUTPUT_DIR}/variants/all_samples.vcf

TOTAL=$(bcftools view -H ${OUTPUT_DIR}/variants/all_samples.vcf | wc -l)
SNPS=$(bcftools view -H ${OUTPUT_DIR}/variants/all_samples.vcf --types snps | wc -l)
INDELS=$(bcftools view -H ${OUTPUT_DIR}/variants/all_samples.vcf --types indels | wc -l)

echo ""
echo "=========== VARIANT CALLING ==========="
echo "Total Variants = $TOTAL"
echo "Total SNPs = $SNPS"
echo "Total INDELs = $INDELS"
echo ""
grep -v '^#' ${OUTPUT_DIR}/variants/all_samples.vcf | awk 'BEGIN {max=0} {sum+=$6; if ($6>max) {max=$6}} END {print "Average qual: "sum/NR "\tMax qual: " max}' 
echo "======================================="

# ==============================================================================
# STEP 6: PHYLOGENETIC TREE (RAXML-NG)
# ==============================================================================

echo "Assembling tree..."

python scripts/vcf2phylip.py -i ${OUTPUT_DIR}/variants/all_samples.vcf
python scripts/ascbias.py -p .${OUTPUT_DIR}/variants/all_samples.min4.phy -o ${OUTPUT_DIR}/variants/all_samples_final.phy

raxml-ng --all --msa ${OUTPUT_DIR}/variants/all_samples_final.phy --model GTR+ASC_LEWIS --tree pars{10} --bs-trees 100

echo "Pipeline finished successfully at $(date)"