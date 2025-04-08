#!/bin/bash
set -e

echo "Building MT4 files..."

# Navigate to source directory
cd /app/src

# Configure directories
MT4_METAEDITOR_PATH="/root/.wine/drive_c/Program Files/MetaQuotes/MetaEditor"
BUILD_OUTPUT_DIR="/app/build/mt4"

# Ensure build directory exists
mkdir -p "$BUILD_OUTPUT_DIR"

# Compile each MQL4 file
find . -type f -name "*.mq4" | while read -r file; do
    filename=$(basename "$file")
    basename="${filename%.*}"
    
    echo "Compiling: $filename"
    
    # Run MetaEditor compiler in Wine with Xvfb
    xvfb-run wine "$MT4_METAEDITOR_PATH/metaeditor.exe" /compile:"$file" /log:"$BUILD_OUTPUT_DIR/${basename}.log"
    
    # Check if compilation was successful
    ex4_file="${file%.*}.ex4"
    if [ -f "$ex4_file" ]; then
        echo "Compilation successful: $ex4_file"
        # Move compiled file to build directory
        mv "$ex4_file" "$BUILD_OUTPUT_DIR"
    else
        echo "Compilation failed for $file. Check log at $BUILD_OUTPUT_DIR/${basename}.log"
        cat "$BUILD_OUTPUT_DIR/${basename}.log"
    fi
done

# Copy include files
mkdir -p "$BUILD_OUTPUT_DIR/include"
find . -type f -name "*.mqh" -exec cp {} "$BUILD_OUTPUT_DIR/include/" \;

echo "MT4 build complete. Output in $BUILD_OUTPUT_DIR"