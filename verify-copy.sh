#!/bin/bash

# Simple verification script
echo "Checking if modularization was successful..."

BASE_DIR="/Users/rod/Developer/reportmate"

# Check each directory
for dir in reportmate-app-csharp reportmate-app-swift reportmate-app-react reportmate-infra-aws reportmate-infra-azure reportmate-module-core reportmate-module-hardware reportmate-module-software; do
    if [ -d "$BASE_DIR/$dir" ]; then
        file_count=$(find "$BASE_DIR/$dir" -type f 2>/dev/null | wc -l)
        echo "✅ $dir: $file_count files"
    else
        echo "❌ $dir: missing"
    fi
done

echo "Done."
