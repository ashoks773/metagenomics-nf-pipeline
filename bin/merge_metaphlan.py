#!/usr/bin/env python3
"""
Merge multiple MetaPhlAn profile tables into a single table
"""

import sys
import argparse
import pandas as pd
from pathlib import Path

def read_metaphlan_profile(file_path):
    """Read a single MetaPhlAn profile"""
    # Skip comment lines
    with open(file_path, 'r') as f:
        lines = [line for line in f if not line.startswith('#')]
    
    # Read as dataframe
    from io import StringIO
    df = pd.read_csv(StringIO(''.join(lines)), sep='\t')
    
    return df

def merge_profiles(profile_files, sample_names=None):
    """Merge multiple MetaPhlAn profiles"""
    all_profiles = []
    
    for i, file_path in enumerate(profile_files):
        print(f"Reading: {file_path}")
        df = read_metaphlan_profile(file_path)
        
        # Get sample name
        if sample_names and i < len(sample_names):
            sample_name = sample_names[i]
        else:
            # Use filename as sample name
            sample_name = Path(file_path).stem.replace('_profile', '')
        
        # Rename abundance column
        if len(df.columns) >= 2:
            df = df.rename(columns={df.columns[1]: sample_name})
        
        all_profiles.append(df)
    
    # Merge all profiles
    merged = all_profiles[0]
    for df in all_profiles[1:]:
        merged = pd.merge(merged, df, on=df.columns[0], how='outer')
    
    # Fill NaN with 0
    merged = merged.fillna(0)
    
    return merged

def filter_by_level(df, level='species'):
    """Filter table by taxonomic level"""
    level_map = {
        'kingdom': 'k__',
        'phylum': 'p__',
        'class': 'c__',
        'order': 'o__',
        'family': 'f__',
        'genus': 'g__',
        'species': 's__',
        'strain': 't__'
    }
    
    if level not in level_map:
        print(f"Warning: Unknown level '{level}', using 'species'")
        level = 'species'
    
    level_prefix = level_map[level]
    
    # Filter rows that contain the level prefix
    clade_col = df.columns[0]
    
    if level == 'strain':
        # Include strains (contain t__)
        filtered = df[df[clade_col].str.contains('\\|' + level_prefix)]
    else:
        # Exclude strains and filter for level
        filtered = df[
            df[clade_col].str.contains('\\|' + level_prefix) &
            ~df[clade_col].str.contains('\\|t__')
        ]
    
    return filtered

def main():
    parser = argparse.ArgumentParser(
        description='Merge multiple MetaPhlAn profile tables'
    )
    parser.add_argument(
        '-i', '--input',
        nargs='+',
        required=True,
        help='Input MetaPhlAn profile files'
    )
    parser.add_argument(
        '-o', '--output',
        required=True,
        help='Output merged table'
    )
    parser.add_argument(
        '-n', '--names',
        nargs='+',
        help='Sample names (optional, defaults to filenames)'
    )
    parser.add_argument(
        '-l', '--level',
        choices=['kingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species', 'strain', 'all'],
        default='all',
        help='Taxonomic level to extract (default: all)'
    )
    
    args = parser.parse_args()
    
    # Check if input files exist
    for file_path in args.input:
        if not Path(file_path).exists():
            print(f"Error: File not found: {file_path}")
            sys.exit(1)
    
    print(f"Merging {len(args.input)} MetaPhlAn profiles...")
    
    # Merge profiles
    merged = merge_profiles(args.input, args.names)
    
    print(f"Merged table shape: {merged.shape}")
    
    # Filter by level if specified
    if args.level != 'all':
        print(f"Filtering to {args.level} level...")
        merged = filter_by_level(merged, args.level)
        print(f"Filtered table shape: {merged.shape}")
    
    # Write output
    merged.to_csv(args.output, sep='\t', index=False)
    print(f"Merged table written to: {args.output}")
    
    # Print summary statistics
    print("\nSummary:")
    print(f"  Total taxa: {len(merged)}")
    print(f"  Total samples: {len(merged.columns) - 1}")
    
    # Calculate average abundance across samples
    sample_cols = merged.columns[1:]
    merged['mean_abundance'] = merged[sample_cols].mean(axis=1)
    
    print(f"\nTop 10 most abundant taxa (average across samples):")
    top10 = merged.nlargest(10, 'mean_abundance')
    for idx, row in top10.iterrows():
        print(f"  {row[merged.columns[0]]}: {row['mean_abundance']:.2f}%")

if __name__ == '__main__':
    main()
