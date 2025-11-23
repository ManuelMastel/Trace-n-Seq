#!/usr/bin/env bash
set -euo pipefail

#############################################
# User configuration
#############################################

# Project parent directory that contains one folder per cell,
# e.g. /path/to/project/ALIGNMENT/<CELL_ID>/fastq/*.fastq.gz
PARENT_DIR="/path/to/project/ALIGNMENT"

# STAR genome index directory
INDEX_DIR="/path/to/genome_indices/STAR_Mouse_GRCm39"

# Gene annotation GTF for htseq-count
GTF="/path/to/annotation/Mus_musculus.GRCm39.gtf"

# Number of threads for STAR
STAR_THREADS=12

# Module or environment setup
# Comment or adapt these lines as needed for your system
module load STAR/2.7.11b-GCC-14.1.0 || true
module load SAMtools || true
# If htseq-count is in a conda environment:
source ~/miniconda3/bin/activate ~/miniconda3/envs/rnaseq_analysis || true


#############################################
# Input, cell ID
#############################################

SID="${1:-}"
if [[ -z "$SID" ]]; then
  echo "Usage: $0 CELL_ID   (e.g., AS-1698138-LR-81528)" >&2
  exit 1
fi

SAMPLE_DIR="${PARENT_DIR}/${SID}/fastq"
OUTDIR="${SAMPLE_DIR}/aligned_STAR"
PREFIX="${OUTDIR}/${SID}_"   # base prefix for STAR output

#############################################
# Skip if STAR tmp dir already exists
#############################################

shopt -s nullglob
TMPCAND=( "${PREFIX%_}"*_STARtmp )
if (( ${#TMPCAND[@]} )); then
  echo "[SKIP] ${SID}: STAR tmp exists -> ${TMPCAND[0]}"
  exit 0
fi
shopt -u nullglob

mkdir -p "${OUTDIR}"

#############################################
# Detect FASTQ files (paired or single end)
#############################################

R1=$(ls "${SAMPLE_DIR}"/*_R1*.fastq.gz "${SAMPLE_DIR}"/*_1*.fastq.gz "${SAMPLE_DIR}"/*R1*.fastq.gz 2>/dev/null | head -n1 || true)
R2=$(ls "${SAMPLE_DIR}"/*_R2*.fastq.gz "${SAMPLE_DIR}"/*_2*.fastq.gz "${SAMPLE_DIR}"/*R2*.fastq.gz 2>/dev/null | head -n1 || true)

# Fallback: any .fastq.gz as single end if R1 not found
if [[ -z "${R1}" ]]; then
  R1=$(ls "${SAMPLE_DIR}"/*.fastq.gz 2>/dev/null | head -n1 || true)
fi

if [[ -z "${R1}" ]]; then
  echo "[ERROR] ${SID}: No FASTQ files found in ${SAMPLE_DIR}" >&2
  exit 1
fi

echo "[INFO] ${SID}: R1=$(basename "${R1}") R2=$(basename "${R2:-NONE}")"

#############################################
# STAR alignment to sorted BAM
#############################################

STAR \
  --genomeDir "${INDEX_DIR}" \
  --readFilesIn "${R1}" ${R2:+ "${R2}"} \
  --readFilesCommand zcat \
  --runThreadN "${STAR_THREADS}" \
  --outFileNamePrefix "${OUTDIR}/${SID}_" \
  --outSAMtype BAM SortedByCoordinate

BAM="${OUTDIR}/${SID}_Aligned.sortedByCoord.out.bam"

#############################################
# Index BAM
#############################################

samtools index "${BAM}"

#############################################
# Gene level counts with htseq-count
# SMART seq is usually unstranded
#############################################

htseq-count \
  -f bam \
  --stranded no \
  "${BAM}" \
  "${GTF}" > "${OUTDIR}/${SID}_counts.txt"

echo "[DONE] ${SID}"
