#!/usr/bin/env Rscript

#' Plot bacterial growth rates from DEMIC output
#' 
#' This script reads DEMIC growth rate results and creates visualizations

suppressPackageStartupMessages({
  library(optparse)
  library(data.table)
  library(ggplot2)
  library(reshape2)
})

# Parse command line arguments
option_list <- list(
  make_option(c("-i", "--input"), type="character", 
              help="Directory containing DEMIC growth rate files or single file"),
  make_option(c("-o", --output"), type="character", 
              help="Output prefix for plots"),
  make_option(c("-m", "--metadata"), type="character", default=NULL,
              help="Optional metadata file with sample groups")
)

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

if (is.null(opt$input) || is.null(opt$output)) {
  print_help(opt_parser)
  stop("Input and output must be specified", call.=FALSE)
}

# Function to read DEMIC output
read_demic <- function(file) {
  # DEMIC output format may vary, adjust as needed
  df <- fread(file, header=TRUE)
  return(df)
}

# Function to read metadata
read_metadata <- function(file) {
  meta <- fread(file, header=TRUE)
  return(meta)
}

# Main function
main <- function() {
  cat("Reading growth rate data from:", opt$input, "\n")
  
  # Check if input is directory or file
  if (dir.exists(opt$input)) {
    # Read all growth rate files
    growth_files <- list.files(opt$input, pattern="growth_rates?.txt$", 
                               full.names=TRUE, recursive=TRUE)
    
    if (length(growth_files) == 0) {
      stop("No growth rate files found in ", opt$input)
    }
    
    cat("Found", length(growth_files), "growth rate files\n")
    
    # Read and combine all files
    all_data <- lapply(growth_files, function(file) {
      sample_name <- basename(dirname(file))
      data <- read_demic(file)
      data$Sample <- sample_name
      return(data)
    })
    
    growth_data <- rbindlist(all_data, fill=TRUE)
    
  } else if (file.exists(opt$input)) {
    # Single file
    growth_data <- read_demic(opt$input)
  } else {
    stop("Input path does not exist: ", opt$input)
  }
  
  # Ensure required columns exist
  if (!all(c("Sample", "Bin", "GrowthRate") %in% colnames(growth_data))) {
    # Try alternative column names
    possible_names <- c("sample", "bin", "growth_rate", "PTR", "ptr")
    
    if ("sample" %in% colnames(growth_data)) {
      colnames(growth_data)[colnames(growth_data) == "sample"] <- "Sample"
    }
    if ("bin" %in% colnames(growth_data)) {
      colnames(growth_data)[colnames(growth_data) == "bin"] <- "Bin"
    }
    if ("growth_rate" %in% colnames(growth_data) || "PTR" %in% colnames(growth_data)) {
      gr_col <- ifelse("growth_rate" %in% colnames(growth_data), "growth_rate", "PTR")
      colnames(growth_data)[colnames(growth_data) == gr_col] <- "GrowthRate"
    }
  }
  
  # Remove NA growth rates
  growth_data <- growth_data[!is.na(GrowthRate)]
  
  # Add metadata if provided
  if (!is.null(opt$metadata)) {
    metadata <- read_metadata(opt$metadata)
    growth_data <- merge(growth_data, metadata, by="Sample", all.x=TRUE)
  }
  
  # Write combined table
  output_file <- paste0(opt$output, "_growth_rates_combined.txt")
  write.table(growth_data, output_file, sep="\t", quote=FALSE, row.names=FALSE)
  cat("Wrote combined growth rates to:", output_file, "\n")
  
  # Create visualizations
  cat("Creating visualizations...\n")
  
  # 1. Growth rate distribution
  p1 <- ggplot(growth_data, aes(x=GrowthRate)) +
    geom_histogram(bins=30, fill="steelblue", color="black", alpha=0.7) +
    theme_minimal() +
    labs(title="Distribution of bacterial growth rates",
         x="Growth Rate (PTR or similar metric)",
         y="Count")
  
  ggsave(paste0(opt$output, "_growth_rate_distribution.pdf"), 
         p1, width=8, height=6)
  
  # 2. Growth rates by sample
  p2 <- ggplot(growth_data, aes(x=Sample, y=GrowthRate)) +
    geom_boxplot(fill="lightblue", alpha=0.7) +
    geom_jitter(width=0.2, alpha=0.5, size=2) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle=45, hjust=1)) +
    labs(title="Growth rates by sample",
         x="Sample",
         y="Growth Rate")
  
  ggsave(paste0(opt$output, "_growth_rates_by_sample.pdf"), 
         p2, width=10, height=6)
  
  # 3. Top growing bins
  top_bins <- growth_data[order(-GrowthRate)][1:min(20, nrow(growth_data))]
  
  p3 <- ggplot(top_bins, aes(x=reorder(Bin, GrowthRate), y=GrowthRate, fill=Sample)) +
    geom_bar(stat="identity") +
    coord_flip() +
    theme_minimal() +
    labs(title="Top 20 fastest growing bins",
         x="Bin",
         y="Growth Rate")
  
  ggsave(paste0(opt$output, "_top_growing_bins.pdf"), 
         p3, width=10, height=8)
  
  # 4. Heatmap of growth rates (if multiple samples)
  if (length(unique(growth_data$Sample)) > 1) {
    # Reshape data for heatmap
    growth_matrix <- dcast(growth_data, Bin ~ Sample, value.var="GrowthRate", 
                          fun.aggregate=mean)
    
    # Convert to matrix
    mat <- as.matrix(growth_matrix[, -1])
    rownames(mat) <- growth_matrix$Bin
    
    # Remove bins with too many NAs
    mat <- mat[rowSums(!is.na(mat)) >= 2, ]
    
    if (nrow(mat) > 1) {
      pdf(paste0(opt$output, "_growth_rate_heatmap.pdf"), 
          width=10, height=12)
      heatmap(mat, 
              scale="row",
              col=colorRampPalette(c("blue", "white", "red"))(100),
              margins=c(10, 15),
              na.rm=TRUE,
              main="Growth rates across samples (row-normalized)")
      dev.off()
    }
  }
  
  # 5. If metadata with groups, compare groups
  if (!is.null(opt$metadata) && "Group" %in% colnames(growth_data)) {
    p5 <- ggplot(growth_data, aes(x=Group, y=GrowthRate, fill=Group)) +
      geom_boxplot(alpha=0.7) +
      geom_jitter(width=0.2, alpha=0.3) +
      theme_minimal() +
      labs(title="Growth rates by group",
           x="Group",
           y="Growth Rate")
    
    ggsave(paste0(opt$output, "_growth_rates_by_group.pdf"), 
           p5, width=8, height=6)
    
    # Statistical test
    if (length(unique(growth_data$Group)) == 2) {
      test_result <- wilcox.test(GrowthRate ~ Group, data=growth_data)
      cat("\nWilcoxon test between groups:\n")
      cat("  p-value:", test_result$p.value, "\n")
      
      # Write test result
      sink(paste0(opt$output, "_statistical_test.txt"))
      print(test_result)
      sink()
    }
  }
  
  # Summary statistics
  cat("\nSummary statistics:\n")
  cat("  Total bins:", nrow(growth_data), "\n")
  cat("  Mean growth rate:", mean(growth_data$GrowthRate, na.rm=TRUE), "\n")
  cat("  Median growth rate:", median(growth_data$GrowthRate, na.rm=TRUE), "\n")
  cat("  Range:", range(growth_data$GrowthRate, na.rm=TRUE), "\n")
  
  # Write summary
  summary_stats <- data.frame(
    Metric = c("Total_bins", "Mean_growth_rate", "Median_growth_rate", 
               "Min_growth_rate", "Max_growth_rate"),
    Value = c(nrow(growth_data),
              mean(growth_data$GrowthRate, na.rm=TRUE),
              median(growth_data$GrowthRate, na.rm=TRUE),
              min(growth_data$GrowthRate, na.rm=TRUE),
              max(growth_data$GrowthRate, na.rm=TRUE))
  )
  
  write.table(summary_stats, paste0(opt$output, "_growth_rate_summary.txt"),
              sep="\t", quote=FALSE, row.names=FALSE)
  
  cat("\nPlotting complete!\n")
  cat("  Combined data:", output_file, "\n")
  cat("  Plots created in:", dirname(opt$output), "\n")
}

# Run main function
main()
