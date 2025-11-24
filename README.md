# Trace-n-Seq
Repository containing the complete SMART seq two Trace n Seq analysis workflow, including raw and filtered objects, quality control scripts, reference based neuronal annotation, Seurat and SingleCellExperiment pipelines, and code to generate all figures for healthy, pancreatitis and cancer neuron datasets.

Part 1: 

This workflow processes SMART-seq single-cell FASTQ files into a unified gene-by-cell count matrix. Each cell is aligned independently using align_one_cell.sh, which runs STAR with appropriate settings and produces a BAM file plus per-gene read counts. The script submit_align_array.sh automates this by submitting one STAR job per cell to the HPC cluster, enabling large-scale parallel alignment. Once all alignments are finished, process_STAR_counts.R collects the ReadsPerGene.out.tab files, extracts gene counts, and merges them into a single matrix. The final output is a clean expression matrix (and an SCE object) ready for downstream single-cell analysis with Seurat, SingleCellExperiment, or Scanpy.

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
Purpose:
Generate the count matrix required for downstream Seurat/SCE analysis.

Part 2: 

This covers the full downstream processing, QC, and biological interpretation of the SMART-seq2 dataset after alignment. The R Markdown workflow (Trace-n-Seq SMART-seq2 R Analysis) loads the STAR-generated count matrix, performs quality control, normalization, and detection of highly variable genes, and constructs a Seurat or SingleCellExperiment object. It then applies dimensionality reduction (PCA/UMAP), clustering, and annotation of neuronal subtypes using SingleR and curated gene signatures. Additional analyses include differential expression, detection of marker genes, and scoring of functional neuronal programs relevant to Trace-n-Seq. The final output is a fully annotated, biologically interpretable single-cell atlas of tissue-innervating neurons, presented both as an R Markdown notebook and an HTML report (Trace-n-Seq SMART-seq2 R Analysis.html)
sce.rds with gene counts + cell metadata



