#!/usr/bin/env python3
"""
Parse KEGG BLAST results and summarize functional annotations
"""

import sys
import argparse
import pandas as pd
from collections import Counter
import re

def parse_blast_results(blast_file):
    """Parse BLAST output file"""
    columns = ['query', 'subject', 'pident', 'length', 'mismatch', 
               'gapopen', 'qstart', 'qend', 'sstart', 'send', 
               'evalue', 'bitscore', 'stitle']
    
    df = pd.read_csv(blast_file, sep='\t', names=columns, comment='#')
    return df

def extract_ko_id(subject_id):
    """Extract KO ID from subject identifier"""
    # KEGG format: ko:K00001 or K00001
    match = re.search(r'(K\d{5})', subject_id)
    if match:
        return match.group(1)
    return None

def extract_pathway(stitle):
    """Extract pathway information from subject title"""
    # Look for pathway identifiers in format [PATH:ko00010]
    match = re.search(r'\[PATH:(ko\d{5})\]', stitle)
    if match:
        return match.group(1)
    return None

def summarize_kegg(df, identity_threshold=50, evalue_threshold=1e-5):
    """Summarize KEGG annotations"""
    # Filter by quality thresholds
    filtered = df[
        (df['pident'] >= identity_threshold) &
        (df['evalue'] <= evalue_threshold)
    ]
    
    print(f"Total hits: {len(df)}")
    print(f"Filtered hits (identity>={identity_threshold}%, evalue<={evalue_threshold}): {len(filtered)}")
    
    # Extract KO IDs
    filtered['ko_id'] = filtered['subject'].apply(extract_ko_id)
    filtered['pathway'] = filtered['stitle'].apply(extract_pathway)
    
    # Count KO occurrences
    ko_counts = Counter(filtered['ko_id'].dropna())
    pathway_counts = Counter(filtered['pathway'].dropna())
    
    return filtered, ko_counts, pathway_counts

def write_summary(ko_counts, pathway_counts, output_prefix):
    """Write summary files"""
    # KO summary
    ko_file = f"{output_prefix}_ko_summary.txt"
    with open(ko_file, 'w') as f:
        f.write("KO_ID\tCount\n")
        for ko, count in ko_counts.most_common():
            f.write(f"{ko}\t{count}\n")
    print(f"KO summary written to {ko_file}")
    
    # Pathway summary
    pathway_file = f"{output_prefix}_pathway_summary.txt"
    with open(pathway_file, 'w') as f:
        f.write("Pathway_ID\tCount\n")
        for pathway, count in pathway_counts.most_common():
            f.write(f"{pathway}\t{count}\n")
    print(f"Pathway summary written to {pathway_file}")

def write_detailed_annotations(df, output_file):
    """Write detailed annotations"""
    df_out = df[['query', 'ko_id', 'pathway', 'pident', 'evalue', 'stitle']]
    df_out.to_csv(output_file, sep='\t', index=False)
    print(f"Detailed annotations written to {output_file}")

def main():
    parser = argparse.ArgumentParser(
        description='Parse KEGG BLAST results and summarize annotations'
    )
    parser.add_argument(
        '-i', '--input',
        required=True,
        help='BLAST results file (tabular format)'
    )
    parser.add_argument(
        '-o', '--output-prefix',
        required=True,
        help='Output file prefix'
    )
    parser.add_argument(
        '--identity',
        type=float,
        default=50,
        help='Minimum identity percentage (default: 50)'
    )
    parser.add_argument(
        '--evalue',
        type=float,
        default=1e-5,
        help='Maximum E-value (default: 1e-5)'
    )
    
    args = parser.parse_args()
    
    # Parse BLAST results
    print(f"Parsing BLAST results from {args.input}...")
    df = parse_blast_results(args.input)
    
    # Summarize KEGG annotations
    filtered_df, ko_counts, pathway_counts = summarize_kegg(
        df,
        identity_threshold=args.identity,
        evalue_threshold=args.evalue
    )
    
    # Write outputs
    write_summary(ko_counts, pathway_counts, args.output_prefix)
    write_detailed_annotations(
        filtered_df,
        f"{args.output_prefix}_detailed_annotations.txt"
    )
    
    # Print statistics
    print(f"\nStatistics:")
    print(f"  Unique KOs: {len(ko_counts)}")
    print(f"  Unique pathways: {len(pathway_counts)}")
    print(f"  Annotated genes: {len(filtered_df)}")

if __name__ == '__main__':
    main()
