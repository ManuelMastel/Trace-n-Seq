#!/usr/bin/env bash
set -euo pipefail

#############################################
# CONFIG
#############################################

# Project parent directory that contains one folder per cell:
#   /path/to/project/ALIGNMENT/<CELL_ID>/fastq/*.fastq.gz
PARENT_DIR="/path/to/project/ALIGNMENT"

# Name of the alignment script that processes a single cell
SCRIPT_NAME="align_one_cell.sh"

# LSF queue, resources and job name base
LSF_QUEUE="long"
LSF_CPUS=12
LSF_MEM=32000          # in MB
JOB_NAME_BASE="align_project"

#############################################
# Setup
#############################################

cd "${PARENT_DIR}"

# Ensure alignment script is executable
chmod +x "${SCRIPT_NAME}"

#############################################
# 1) Build list of cell IDs
#    expects: PARENT_DIR/CELL_ID/fastq/*.fastq.gz
#############################################

find . -maxdepth 2 -type d -name fastq \
  | sed 's|^\./||; s|/fastq||' \
  | sort -u > cell_ids.txt

echo "[INFO] Wrote cell IDs to cell_ids.txt:"
head cell_ids.txt || true

N=$(wc -l < cell_ids.txt)
if [[ "${N}" -eq 0 ]]; then
  echo "[ERROR] No cell IDs found inside ${PARENT_DIR} (no */fastq directories?)." >&2
  exit 1
fi

echo "[INFO] Found ${N} cells."

#############################################
# 2) Log directory
#############################################

mkdir -p logs

#############################################
# 3) Submit LSF array job
#############################################

bsub -q "${LSF_QUEUE}" \
     -n "${LSF_CPUS}" \
     -R "rusage[mem=${LSF_MEM}]" \
     -J "${JOB_NAME_BASE}[1-${N}]" \
     -oo "logs/%J_%I.out" \
     -eo "logs/%J_%I.err" \
     'SID=$(sed -n "${LSB_JOBINDEX}p" cell_ids.txt); ./'"${SCRIPT_NAME}"' "$SID"'

echo "[INFO] Submitted LSF array job ${JOB_NAME_BASE}[1-${N}]"
