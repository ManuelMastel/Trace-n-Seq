#!/usr/bin/env Rscript

# -------------------------------------------------------------------
# Combine htseq-count output files from multiple single-cell samples
# into one gene-by-cell count matrix.
# -------------------------------------------------------------------

# Set the parent directory that contains dataset folders
# Example structure:
# /path/to/ALIGNMENT/<DATASET>/<CELL_ID>/fastq/aligned_STAR/<CELL_ID>_counts.txt
parent.path <- "/path/to/project/ALIGNMENT"

# Specify which dataset to combine (folder inside parent.path)
dataset <- "DATASET_NAME"

# Construct path to dataset
data.path <- file.path(parent.path, dataset)

# List sample folders at the top level of dataset directory
samples <- list.dirs(data.path, recursive = FALSE, full.names = FALSE)

# Exclude non-sample folders
samples <- samples[!grepl("Undetermined|fastq|job_out", samples)]

# Build full file paths to each counts.txt file
files.data <- file.path(
  data.path,
  samples,
  "fastq",
  "aligned_STAR",
  paste0(samples, "_counts.txt")
)

# Keep only existing files
files.data <- files.data[file.exists(files.data)]

if (length(files.data) == 0) {
  stop("No counts files found. Check your folder structure.")
}

# Load and column-bind all count files
data.full <- do.call("cbind", lapply(files.data, function(f) {
  read.table(f, sep = "\t", header = FALSE, row.names = 1)
}))

# Assign column names based on sample IDs
colnames(data.full) <- samples[1:ncol(data.full)]

# Write final combined matrix
output.file <- file.path(parent.path, paste0(dataset, "_combined_counts.csv"))
write.csv(data.full, output.file)

cat("Combined counts matrix written to:", output.file, "\n")
