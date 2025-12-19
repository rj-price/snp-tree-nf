Pipeline Inputs:
1. Samplesheet (sample_id,read1,read2)
2. Reference genome (fasta)

Pipeline Steps:
1. Quality control raw reads with FastQC
2. Trim poor quality sequence and adapters with Trimmomatic (ILLUMINACLIP, SLIDINGWINDOW:4:20, MINLEN:36, HEADCROP:10)
3. Quality control trimmed reads with FastQC
4. Index genome with BWA
5. Read alignment with BWA-MEM (specify read group based on sample_id)
6. Convert to BAM, index and calculate stats with Samtools
7. Index genome with Samtools faidx
7. Variant calling with bcftools mpileup & call
8. Variant filtering with bcftools (SNPs only, QUAL>=20 && DP>=10 && MQ>=30)
9. Convert VCF to PHYLIP format
10. Phylogenetic tree construction using PHYLIP file with RAxML
11. Convert VCF to NEXUS format for SplitsTree (separate from pipeline)
12. MultiQC report