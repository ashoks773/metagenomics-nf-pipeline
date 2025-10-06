cat > test/README.md << 'EOF'
# Test Data

This directory contains small test datasets for pipeline validation.

## Running Tests
```bash
# Quick test (taxonomy only)
nextflow run ../main.nf \
    --input test_samplesheet.csv \
    --outdir test_results \
    --skip_assembly \
    --skip_binning \
    --skip_growth_
