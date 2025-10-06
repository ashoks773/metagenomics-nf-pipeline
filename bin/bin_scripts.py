#!/usr/bin/env python3
"""
Filter bins based on CheckM quality metrics
"""

import sys
import argparse
import pandas as pd
from pathlib import Path

def parse_checkm_results(checkm_file):
    """Parse CheckM output file"""
    df = pd.read_csv(checkm_file, sep='\t')
    return df

def filter_bins(df, min_completeness=50, max_contamination=10, min_length=None):
    """Filter bins by quality thresholds"""
    # Filter by completeness and contamination
    filtered = df[
        (df['Completeness'] >= min_completeness) &
        (df['Contamination'] <= max_contamination)
    ]
    
    # Optional: filter by genome length
    if min_length:
        filtered = filtered[filtered['Genome size (bp)'] >= min_length]
    
    return filtered

def write_filtered_list(filtered_df, output_file):
    """Write list of high-quality bins"""
    with open(output_file, 'w') as f:
        f.write("Bin_Id\tCompleteness\tContamination\tStrain_heterogeneity\n")
        for _, row in filtered_df.iterrows():
            f.write(f"{row['Bin Id']}\t{row['Completeness']:.2f}\t"
                   f"{row['Contamination']:.2f}\t{row['Strain heterogeneity']:.2f}\n")

def main():
    parser = argparse.ArgumentParser(
        description='Filter bins based on CheckM quality metrics'
    )
    parser.add_argument(
        '-i', '--input',
        required=True,
        help='CheckM results file'
    )
    parser.add_argument(
        '-o', '--output',
        required=True,
        help='Output file with filtered bins'
    )
    parser.add_argument(
        '--min-completeness',
        type=float,
        default=50,
        help='Minimum completeness percentage (default: 50)'
    )
    parser.add_argument(
        '--max-contamination',
        type=float,
        default=10,
        help='Maximum contamination percentage (default: 10)'
    )
    parser.add_argument(
        '--min-length',
        type=int,
        help='Minimum genome length in bp (optional)'
    )
    parser.add_argument(
        '--stats',
        help='Output statistics file'
    )
    
    args = parser.parse_args()
    
    # Parse CheckM results
    print(f"Reading CheckM results from {args.input}...")
    df = parse_checkm_results(args.input)
    
    print(f"Total bins: {len(df)}")
    
    # Filter bins
    filtered_df = filter_bins(
        df,
        min_completeness=args.min_completeness,
        max_contamination=args.max_contamination,
        min_length=args.min_length
    )
    
    print(f"High-quality bins: {len(filtered_df)}")
    print(f"  Completeness >= {args.min_completeness}%")
    print(f"  Contamination <= {args.max_contamination}%")
    
    # Write filtered results
    write_filtered_list(filtered_df, args.output)
    print(f"Filtered bins written to {args.output}")
    
    # Write statistics if requested
    if args.stats:
        with open(args.stats, 'w') as f:
            f.write(f"Total bins: {len(df)}\n")
            f.write(f"High-quality bins: {len(filtered_df)}\n")
            f.write(f"Filter criteria:\n")
            f.write(f"  Completeness >= {args.min_completeness}%\n")
            f.write(f"  Contamination <= {args.max_contamination}%\n")
            if args.min_length:
                f.write(f"  Length >= {args.min_length} bp\n")
            
            # Summary statistics
            f.write(f"\nQuality metrics (filtered bins):\n")
            f.write(f"  Mean completeness: {filtered_df['Completeness'].mean():.2f}%\n")
            f.write(f"  Mean contamination: {filtered_df['Contamination'].mean():.2f}%\n")
            f.write(f"  Mean strain heterogeneity: {filtered_df['Strain heterogeneity'].mean():.2f}%\n")

if __name__ == '__main__':
    main()
