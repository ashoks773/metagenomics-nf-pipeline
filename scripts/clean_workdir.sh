cat > scripts/clean_workdir.sh << 'EOF'
#!/bin/bash

# Clean work directory script

WORK_DIR="${1:-work}"

echo "Cleaning work directory: $WORK_DIR"

if [ -d "$WORK_DIR" ]; then
    du -sh "$WORK_DIR"
    read -p "Are you sure you want to delete? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        rm -rf "$WORK_DIR"
        echo "Work directory cleaned"
    else
        echo "Cancelled"
    fi
else
    echo "Work directory not found: $WORK_DIR"
fi
EOF

chmod +x scripts/clean_workdir.sh
