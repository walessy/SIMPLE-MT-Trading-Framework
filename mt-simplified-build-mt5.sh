#!/bin/bash
set -e

echo "Building MT5 files..."

# Navigate to source directory
cd /app/src

# Configure directories
MT5_METAEDITOR_PATH="/root/.wine/drive_c/Program Files/MetaQuotes/MetaEditor 64"
BUILD_OUTPUT_DIR="/app/build/mt5"

# Ensure build directory exists
mkdir -p $BUILD_OUTPUT_DIR

# Compile each MQL5 file
find . -type f -name "*.mq5" | while read -r file; do
    filename=$(basename "$file")
    basename="${filename%.*}"
    
    echo "Compiling: $filename"
    
    # Run MetaEditor compiler in Wine with Xvfb
    xvfb-run wine "$MT5_METAEDITOR_PATH/metaeditor64.exe" /compile:"$file" /log:"$BUILD_OUTPUT_DIR/${basename}.log"
    
    # Check if compilation was successful
    ex5_file="${file%.*}.ex5"
    if [ -f "$ex5_file" ]; then
        echo "Compilation successful: $ex5_file"
        # Move compiled file to build directory
        mv "$ex5_file" "$BUILD_OUTPUT_DIR"
    else
        echo "Compilation failed for $file. Check log at $BUILD_OUTPUT_DIR/${basename}.log"
        cat "$BUILD_OUTPUT_DIR/${basename}.log"
    fi
done

# Copy include files
mkdir -p "$BUILD_OUTPUT_DIR/include"
find . -type f -name "*.mqh" -exec cp {} "$BUILD_OUTPUT_DIR/include/" \;

echo "MT5 build complete. Output in $BUILD_OUTPUT_DIR"