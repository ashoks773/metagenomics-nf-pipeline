#!/usr/bin/env python3
"""
Parse CAZy BLAST results and summarize carbohydrate-active enzyme annotations
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

def extract_cazy_family(subject_id):
    """Extract CAZy family from subject identifier"""
    # CAZy families: GH1, GT2, PL3, CE4, AA5, CBM6, etc.
    match = re.search(r'(GH|GT|PL|CE|AA|CBM)(\d+)', subject_id)
    if match:
        return f"{match.group(1)}{match.group(2)}"
    return None

def extract_cazy_class(family):
    """Extract CAZy class from family"""
    if family:
        return re.match(r'([A-Z]+)', family).group(1)
    return None

def summarize_cazy(df, identity_threshold=40, evalue_threshold=1e-5):
    """Summarize CAZy annotations"""
    # Filter by quality thresholds
    filtered = df[
        (df['pident'] >= identity_threshold) &
        (df['evalue'] <= evalue_threshold)
    ]
    
    print(f"Total hits: {len(df)}")
    print(f"Filtered hits (identity>={identity_threshold}%, evalue<={evalue_threshold}): {len(filtered)}")
    
    # Extract CAZy families
    filtered['cazy_family'] = filtered['subject'].apply(extract_cazy_family)
    filtered['cazy_class'] = filtered['cazy_family'].apply(extract_cazy_class)
    
    # Count occurrences
    family_counts = Counter(filtered['cazy_family'].dropna())
    class_counts = Counter(filtered['cazy_class'].dropna())
    
    return filtered, family_counts, class_counts

def write_summary(family_counts, class_counts, output_prefix):
    """Write summary files"""
    # Family summary
    family_file = f"{output_prefix}_family_summary.txt"
    with open(family_file, 'w') as f:
        f.write("CAZy_Family\tCount\tDescription\n")
        
        # Add descriptions for major families
        descriptions = {
            'GH': 'Glycoside Hydrolases',
            'GT': 'Glycosyltransferases',
            'PL': 'Polysaccharide Lyases',
            'CE': 'Carbohydrate Esterases',
            'AA': 'Auxiliary Activities',
            'CBM': 'Carbohydrate-Binding Modules'
        }
        
        for family, count in family_counts.most_common():
            class_code = re.match(r'([A-Z]+)', family).group(1)
            desc = descriptions.get(class_code, 'Unknown')
            f.write(f"{family}\t{count}\t{desc}\n")
    print(f"Family summary written to {family_file}")
    
    # Class summary
    class_file = f"{output_prefix}_class_summary.txt"
    with open(class_file, 'w') as f:
        f.write("CAZy_Class\tCount\tDescription\n")
        descriptions = {
            'GH': 'Glycoside Hydrolases - enzymes that hydrolyze glycosidic bonds',
            'GT': 'Glycosyltransferases - enzymes that form glycosidic bonds',
            'PL': 'Polysaccharide Lyases - enzymes that cleave polysaccharides',
            'CE': 'Carbohydrate Esterases - enzymes that remove ester modifications',
            'AA': 'Auxiliary Activities - redox enzymes acting on lignin and polysaccharides',
            'CBM': 'Carbohydrate-Binding Modules - modules that bind carbohydrates'
        }
        
        for cazy_class, count in class_counts.most_common():
            desc = descriptions.get(cazy_class, 'Unknown')
            f.write(f"{cazy_class}\t{count}\t{desc}\n")
    print(f"Class summary written to {class_file}")

def write_detailed_annotations(df, output_file):
    """Write detailed annotations"""
    df_out = df[['query', 'cazy_family', 'cazy_class', 'pident', 'evalue', 'stitle']]
    df_out.to_csv(output_file, sep='\t', index=False)
    print(f"Detailed annotations written to {output_file}")

def main():
    parser = argparse.ArgumentParser(
        description='Parse CAZy BLAST results and summarize annotations'
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
        default=40,
        help='Minimum identity percentage (default: 40)'
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
    
    # Summarize CAZy annotations
    filtered_df, family_counts, class_counts = summarize_cazy(
        df,
        identity_threshold=args.identity,
        evalue_threshold=args.evalue
    )
    
    # Write outputs
    write_summary(family_counts, class_counts, args.output_prefix)
    write_detailed_annotations(
        filtered_df,
        f"{args.output_prefix}_detailed_annotations.txt"
    )
    
    # Print statistics
    print(f"\nStatistics:")
    print(f"  Unique CAZy families: {len(family_counts)}")
    print(f"  Unique CAZy classes: {len(class_counts)}")
    print(f"  Annotated genes: {len(filtered_df)}")
    print(f"\nTop 10 CAZy families:")
    for family, count in family_counts.most_common(10):
        print(f"  {family}: {count}")

if __name__ == '__main__':
    main()
