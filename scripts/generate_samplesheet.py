cat > scripts/generate_samplesheet.py << 'EOF'
#!/usr/bin/env python3
"""
Generate samplesheet from directory of FASTQ files
"""

import os
import sys
import argparse
import re
from pathlib import Path

def find_fastq_pairs(directory, pattern):
    """Find paired FASTQ files in directory"""
    fastq_files = {}
    
    for file in Path(directory).glob(pattern):
        filename = file.name
        # Extract sample name (everything before _R1 or _R2)
        match = re.search(r'(.+?)_R([12])', filename)
        if match:
            sample = match.group(1)
            read = match.group(2)
            
            if sample not in fastq_files:
                fastq_files[sample] = {}
            fastq_files[sample][f'R{read}'] = str(file.absolute())
    
    return fastq_files

def write_samplesheet(fastq_files, output):
    """Write samplesheet CSV"""
    with open(output, 'w') as f:
        f.write('sample,fastq_1,fastq_2\n')
        for sample, reads in sorted(fastq_files.items()):
            if 'R1' in reads and 'R2' in reads:
                f.write(f'{sample},{reads["R1"]},{reads["R2"]}\n')
            else:
                print(f"Warning: Incomplete pair for {sample}", file=sys.stderr)

def main():
    parser = argparse.ArgumentParser(description='Generate samplesheet from FASTQ directory')
    parser.add_argument('--directory', required=True, help='Directory containing FASTQ files')
    parser.add_argument('--output', required=True, help='Output samplesheet CSV')
    parser.add_argument('--pattern', default='*_R*.fastq.gz', help='FASTQ file pattern')
    
    args = parser.parse_args()
    
    fastq_files = find_fastq_pairs(args.directory, args.pattern)
    write_samplesheet(fastq_files, args.output)
    
    print(f"Generated samplesheet with {len(fastq_files)} samples: {args.output}")

if __name__ == '__main__':
    main()
EOF

chmod +x scripts/generate_samplesheet.py
