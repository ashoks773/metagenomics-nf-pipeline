#!/usr/bin/env Rscript

#' Summarize and visualize HUMAnN functional profiles
#' 
#' This script reads HUMAnN output files and creates summary tables and visualizations

suppressPackageStartupMessages({
  library(optparse)
  library(data.table)
  library(ggplot2)
  library(reshape2)
  library(RColorBrewer)
})

# Parse command line arguments
option_list <- list(
  make_option(c("-i", "--input"), type="character", 
              help="Directory containing HUMAnN output files"),
  make_option(c("-o", "--output"), type="character", 
              help="Output prefix for results"),
  make_option(c("-t", "--type"), type="character", default="pathabundance",
              help="File type: pathabundance, pathcoverage, or genefamilies [default: pathabundance]"),
  make_option(c("-n", "--top"), type="integer", default=30,
              help="Number of top features to plot [default: 30]")
)

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

if (is.null(opt$input) || is.null(opt$output)) {
  print_help(opt_parser)
  stop("Input directory and output prefix must be specified", call.=FALSE)
}

# Function to read HUMAnN output
read_humann <- function(file) {
  df <- fread(file, header=TRUE)
  return(df)
}

# Function to merge HUMAnN tables
merge_humann_tables <- function(file_list) {
  all_data <- list()
  
  for (file in file_list) {
    sample_name <- sub(paste0("_", opt$type, ".tsv"), "", basename(file))
    cat("  Reading:", sample_name, "\n")
    
    data <- read_humann(file)
    colnames(data) <- c("Feature", sample_name)
    all_data[[sample_name]] <- data
  }
  
  # Merge all samples
  merged <- Reduce(function(x, y) merge(x, y, by="Feature", all=TRUE), all_data)
  merged[is.na(merged)] <- 0
  
  return(merged)
}

# Function to filter stratified features
filter_unstratified <- function(data) {
  # Keep only unstratified features (without "|")
  data[!grepl("\\|", Feature)]
}

# Function to normalize to relative abundance
normalize_abundance <- function(data) {
  sample_cols <- setdiff(colnames(data), "Feature")
  
  for (col in sample_cols) {
    total <- sum(data[[col]])
    if (total > 0) {
      data[[col]] <- (data[[col]] / total) * 100
    }
  }
  
  return(data)
}

# Main function
main <- function() {
  cat("Reading HUMAnN", opt$type, "files from:", opt$input, "\n")
  
  # Get all output files of specified type
  pattern <- paste0("_", opt$type, ".tsv$")
  output_files <- list.files(opt$input, pattern=pattern, 
                             full.names=TRUE, recursive=TRUE)
  
  if (length(output_files) == 0) {
    stop("No HUMAnN ", opt$type, " files found in ", opt$input)
  }
  
  cat("Found", length(output_files), opt$type, "files\n")
  
  # Merge all tables
  merged_data <- merge_humann_tables(output_files)
  
  # Filter to unstratified only
  unstratified <- filter_unstratified(merged_data)
  
  # Normalize if pathabundance or genefamilies
  if (opt$type %in% c("pathabundance", "genefamilies")) {
    unstratified <- normalize_abundance(unstratified)
  }
  
  # Write merged table
  output_file <- paste0(opt$output, "_", opt$type, "_merged.txt")
  write.table(unstratified, output_file, sep="\t", quote=FALSE, row.names=FALSE)
  cat("Wrote merged table to:", output_file, "\n")
  
  # Calculate summary statistics
  sample_cols <- setdiff(colnames(unstratified), "Feature")
  abundance_matrix <- as.matrix(unstratified[, sample_cols, with=FALSE])
  rownames(abundance_matrix) <- unstratified$Feature
  
  unstratified$mean_value <- rowMeans(abundance_matrix)
  unstratified$max_value <- apply(abundance_matrix, 1, max)
  unstratified$prevalence <- rowSums(abundance_matrix > 0)
  
  # Remove UNMAPPED and UNINTEGRATED
  unstratified <- unstratified[!grepl("UNMAPPED|UNINTEGRATED", Feature)]
  
  # Write summary
  summary_file <- paste0(opt$output, "_", opt$type, "_summary.txt")
  summary_cols <- c("Feature", "mean_value", "max_value", "prevalence")
  summary_data <- unstratified[order(-mean_value), ..summary_cols]
  write.table(summary_data, summary_file, sep="\t", quote=FALSE, row.names=FALSE)
  cat("Wrote summary statistics to:", summary_file, "\n")
  
  # Create visualizations
  cat("Creating visualizations...\n")
  
  # Select top features
  top_features <- head(unstratified[order(-mean_value)], opt$top)
  top_abundance <- abundance_matrix[top_features$Feature, , drop=FALSE]
  
  # 1. Barplot
  plot_data <- melt(top_abundance)
  colnames(plot_data) <- c("Feature", "Sample", "Value")
  
  # Simplify feature names for plotting
  plot_data$Feature <- sub(":.*", "", plot_data$Feature)
  plot_data$Feature <- sub("\\|.*", "", plot_data$Feature)
  
  p1 <- ggplot(plot_data, aes(x=Sample, y=Value, fill=Feature)) +
    geom_bar(stat="identity") +
    scale_fill_manual(values=colorRampPalette(brewer.pal(12, "Set3"))(opt$top)) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle=45, hjust=1),
          legend.position="right",
          legend.text = element_text(size=8)) +
    labs(title=paste("Top", opt$top, opt$type),
         x="Sample", 
         y=ifelse(opt$type == "pathcoverage", "Coverage (%)", "Relative Abundance (%)"))
  
  ggsave(paste0(opt$output, "_", opt$type, "_barplot.pdf"), 
         p1, width=14, height=8)
  
  # 2. Heatmap
  if (nrow(top_abundance) > 1) {
    # Normalize for heatmap
    top_abundance_norm <- t(scale(t(top_abundance)))
    
    # Simplify row names
    rownames(top_abundance_norm) <- sub(":.*", "", rownames(top_abundance_norm))
    rownames(top_abundance_norm) <- sub("\\|.*", "", rownames(top_abundance_norm))
    
    pdf(paste0(opt$output, "_", opt$type, "_heatmap.pdf"), 
        width=12, height=10)
    heatmap(top_abundance_norm, 
            scale="none",
            col=colorRampPalette(c("blue", "white", "red"))(100),
            margins=c(10, 25),
            cexRow=0.7,
            cexCol=0.9,
            main=paste("Top", opt$top, opt$type, "(normalized)"))
    dev.off()
  }
  
  # 3. Feature richness per sample
  richness <- colSums(abundance_matrix > 0)
  richness_data <- data.frame(
    Sample = names(richness),
    Richness = richness
  )
  
  p3 <- ggplot(richness_data, aes(x=Sample, y=Richness)) +
    geom_bar(stat="identity", fill="steelblue") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle=45, hjust=1)) +
    labs(title=paste("Functional richness -", opt$type),
         x="Sample", 
         y="Number of Features")
  
  ggsave(paste0(opt$output, "_", opt$type, "_richness.pdf"), 
         p3, width=10, height=6)
  
  # Write richness table
  richness_file <- paste0(opt$output, "_", opt$type, "_richness.txt")
  write.table(richness_data, richness_file, sep="\t", 
              quote=FALSE, row.names=FALSE)
  
  cat("\nSummary complete!\n")
  cat("  Merged table:", output_file, "\n")
  cat("  Summary statistics:", summary_file, "\n")
  cat("  Visualizations:\n")
  cat("    - Barplot:", paste0(opt$output, "_", opt$type, "_barplot.pdf\n"))
  cat("    - Heatmap:", paste0(opt$output, "_", opt$type, "_heatmap.pdf\n"))
  cat("    - Richness:", paste0(opt$output, "_", opt$type, "_richness.pdf\n"))
}

# Run main function
main()