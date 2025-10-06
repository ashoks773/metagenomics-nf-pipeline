#!/usr/bin/env Rscript

#' Summarize and visualize MetaPhlAn taxonomic profiles
#' 
#' This script reads MetaPhlAn output files, merges them, and creates
#' summary tables and visualizations

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
              help="Directory containing MetaPhlAn profile files"),
  make_option(c("-o", "--output"), type="character", 
              help="Output prefix for results"),
  make_option(c("-l", "--level"), type="character", default="species",
              help="Taxonomic level to summarize [default: species]"),
  make_option(c("-t", "--top"), type="integer", default=20,
              help="Number of top taxa to plot [default: 20]")
)

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

if (is.null(opt$input) || is.null(opt$output)) {
  print_help(opt_parser)
  stop("Input directory and output prefix must be specified", call.=FALSE)
}

# Function to read MetaPhlAn profile
read_metaphlan <- function(file) {
  # Read profile, skip comment lines
  df <- fread(file, skip="#", header=TRUE)
  colnames(df)[1] <- "clade_name"
  return(df)
}

# Function to extract taxonomic level
extract_level <- function(profiles, level="species") {
  level_prefix <- switch(level,
    kingdom = "k__",
    phylum = "p__",
    class = "c__",
    order = "o__",
    family = "f__",
    genus = "g__",
    species = "s__",
    "s__"
  )
  
  # Filter for specified level
  filtered <- profiles[grepl(paste0("\\|", level_prefix), clade_name) & 
                       !grepl("\\|t__", clade_name)]
  
  # Extract taxon name
  filtered$taxon <- sub(paste0(".*\\|", level_prefix), "", filtered$clade_name)
  
  return(filtered)
}

# Main function
main <- function() {
  cat("Reading MetaPhlAn profiles from:", opt$input, "\n")
  
  # Get all profile files
  profile_files <- list.files(opt$input, pattern="_profile.txt$", 
                             full.names=TRUE, recursive=TRUE)
  
  if (length(profile_files) == 0) {
    stop("No MetaPhlAn profile files found in ", opt$input)
  }
  
  cat("Found", length(profile_files), "profile files\n")
  
  # Read all profiles
  all_profiles <- list()
  for (file in profile_files) {
    sample_name <- basename(dirname(file))
    cat("  Reading:", sample_name, "\n")
    profile <- read_metaphlan(file)
    
    if (ncol(profile) >= 2) {
      colnames(profile)[2] <- sample_name
      all_profiles[[sample_name]] <- profile
    }
  }
  
  # Merge profiles
  merged <- Reduce(function(x, y) merge(x, y, by="clade_name", all=TRUE), 
                   all_profiles)
  
  # Replace NA with 0
  merged[is.na(merged)] <- 0
  
  # Extract specified taxonomic level
  level_data <- extract_level(merged, opt$level)
  
  # Create abundance matrix
  sample_cols <- setdiff(colnames(level_data), c("clade_name", "taxon"))
  abundance_matrix <- as.matrix(level_data[, sample_cols, with=FALSE])
  rownames(abundance_matrix) <- level_data$taxon
  
  # Write merged table
  output_file <- paste0(opt$output, "_", opt$level, "_abundance.txt")
  write.table(level_data, output_file, sep="\t", quote=FALSE, row.names=FALSE)
  cat("Wrote abundance table to:", output_file, "\n")
  
  # Calculate summary statistics
  level_data$mean_abundance <- rowMeans(abundance_matrix)
  level_data$max_abundance <- apply(abundance_matrix, 1, max)
  level_data$prevalence <- rowSums(abundance_matrix > 0)
  
  # Write summary statistics
  summary_file <- paste0(opt$output, "_", opt$level, "_summary.txt")
  summary_cols <- c("taxon", "mean_abundance", "max_abundance", "prevalence")
  summary_data <- level_data[order(-mean_abundance), ..summary_cols]
  write.table(summary_data, summary_file, sep="\t", quote=FALSE, row.names=FALSE)
  cat("Wrote summary statistics to:", summary_file, "\n")
  
  # Create visualizations
  cat("Creating visualizations...\n")
  
  # 1. Barplot of top taxa
  top_taxa <- head(level_data[order(-mean_abundance)], opt$top)
  top_abundance <- abundance_matrix[top_taxa$taxon, , drop=FALSE]
  
  # Prepare data for plotting
  plot_data <- melt(top_abundance)
  colnames(plot_data) <- c("Taxon", "Sample", "Abundance")
  
  # Create stacked barplot
  p1 <- ggplot(plot_data, aes(x=Sample, y=Abundance, fill=Taxon)) +
    geom_bar(stat="identity") +
    scale_fill_manual(values=colorRampPalette(brewer.pal(12, "Set3"))(opt$top)) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle=45, hjust=1),
          legend.position="right") +
    labs(title=paste("Top", opt$top, opt$level, "abundance"),
         x="Sample", y="Relative Abundance (%)")
  
  ggsave(paste0(opt$output, "_", opt$level, "_barplot.pdf"), 
         p1, width=12, height=8)
  
  # 2. Heatmap
  if (nrow(top_abundance) > 1) {
    # Normalize for heatmap
    top_abundance_norm <- t(scale(t(top_abundance)))
    
    pdf(paste0(opt$output, "_", opt$level, "_heatmap.pdf"), 
        width=10, height=8)
    heatmap(top_abundance_norm, 
            scale="none",
            col=colorRampPalette(c("blue", "white", "red"))(100),
            margins=c(10, 15),
            main=paste("Top", opt$top, opt$level, "(normalized)"))
    dev.off()
  }
  
  # 3. Alpha diversity (Shannon index)
  shannon <- apply(abundance_matrix, 2, function(x) {
    x <- x[x > 0]
    -sum(x/100 * log(x/100))
  })
  
  diversity_data <- data.frame(
    Sample = names(shannon),
    Shannon = shannon
  )
  
  p3 <- ggplot(diversity_data, aes(x=Sample, y=Shannon)) +
    geom_bar(stat="identity", fill="steelblue") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle=45, hjust=1)) +
    labs(title="Alpha diversity (Shannon index)",
         x="Sample", y="Shannon Index")
  
  ggsave(paste0(opt$output, "_", opt$level, "_diversity.pdf"), 
         p3, width=10, height=6)
  
  # Write diversity table
  diversity_file <- paste0(opt$output, "_", opt$level, "_diversity.txt")
  write.table(diversity_data, diversity_file, sep="\t", 
              quote=FALSE, row.names=FALSE)
  
  cat("\nSummary complete!\n")
  cat("  Abundance table:", output_file, "\n")
  cat("  Summary statistics:", summary_file, "\n")
  cat("  Visualizations:\n")
  cat("    - Barplot:", paste0(opt$output, "_", opt$level, "_barplot.pdf\n"))
  cat("    - Heatmap:", paste0(opt$output, "_", opt$level, "_heatmap.pdf\n"))
  cat("    - Diversity:", paste0(opt$output, "_", opt$level, "_diversity.pdf\n"))
}

# Run main function
main()
