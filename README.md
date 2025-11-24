# Trace-n-Seq
Repository containing the complete SMART seq two Trace n Seq analysis workflow, including raw and filtered objects, quality control scripts, reference based neuronal annotation, Seurat and SingleCellExperiment pipelines, and code to generate all figures for healthy, pancreatitis and cancer neuron datasets.


1. align_one_cell.sh — Align a single cell with STAR

This script performs per-cell alignment using STAR.
What it does:
Takes a cell ID (SID) and the corresponding FASTQ files (single- or paired-end).

Runs STAR alignment with:
--readFilesCommand zcat
--outSAMtype BAM SortedByCoordinate
12+ threads
Creates an output directory:
aligned_STAR/<SID>/

Produces:
Aligned BAM file
STAR log files
Gene-level read counts (ReadsPerGene.out.tab)
Purpose:
Run STAR independently for each single cell, enabling easy parallelization on a cluster.

2. submit_align_array.sh — Batch submission of many cells (LSF array)

This script submits all cells for alignment to the LSF cluster.
What it does:
Loops over a list of SIDs (cell IDs).
For each ID, submits a STAR job:
bsub -q long-debian \
     -n 12 \
     -R "rusage[mem=16G]" \
     ./align_one_cell.sh $SID
Parallelizes the entire SMART-seq dataset efficiently.
Ensures output goes into per-cell directories under aligned_STAR/.

Purpose:
Use HPC resources to align hundreds/thousands of SMART-seq cells in parallel.

3. process_STAR_counts.R — Build gene × cell count matrix

This R script aggregates STAR count files from all cells and constructs an expression matrix.
What it does:
Reads each cell’s ReadsPerGene.out.tab.
Removes the first four STAR summary rows (N_unmapped, N_multimapping, etc.)
Extracts the correct count column (usually column 2 for unstranded).
Merges all cells into one gene-by-cell matrix.
Creates a SingleCellExperiment object.
Adds metadata and performs basic QC (e.g., percent mitochondrial).

Outputs:
counts_matrix.rds
sce.rds with gene counts + cell metadata

Purpose:
Generate the count matrix required for downstream Seurat/SCE analysis.


