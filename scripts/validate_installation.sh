cat > scripts/validate_installation.sh << 'EOF'
#!/bin/bash

# Validate installation script

echo "Checking installation..."

# Check Nextflow
if command -v nextflow &> /dev/null; then
    echo "✓ Nextflow installed: $(nextflow -version | head -n1)"
else
    echo "✗ Nextflow not found"
fi

# Check Docker
if command -v docker &> /dev/null; then
    echo "✓ Docker installed: $(docker --version)"
else
    echo "✗ Docker not found"
fi

# Check Singularity
if command -v singularity &> /dev/null; then
    echo "✓ Singularity installed: $(singularity --version)"
else
    echo "✗ Singularity not found"
fi

# Check Conda
if command -v conda &> /dev/null; then
    echo "✓ Conda installed: $(conda --version)"
else
    echo "✗ Conda not found"
fi

echo "Validation complete!"
EOF

chmod +x scripts/validate_installation.sh
