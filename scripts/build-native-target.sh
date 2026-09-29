#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)

SRC="$PROJECT_DIR/src/env-info.c"
BUILD_DIR="$PROJECT_DIR/builds"
OUTPUT="$BUILD_DIR/env-info-native-target"

CC="${CC:-gcc}"

CFLAGS=(
    -std=c11
    -Wall
    -Wextra
    -Wpedantic
    -Wshadow
    -Wformat=2
    -O2
    -g
)

if ! command -v "$CC" >/dev/null 2>&1; then
    echo "Error: compiler '$CC' not found." >&2
    exit 1
fi

mkdir -p "$BUILD_DIR"

echo "Native target build"
echo
echo "Compiler : $CC"
echo "Source   : $SRC"
echo "Output   : $OUTPUT"
echo

"$CC" \
    "${CFLAGS[@]}" \
    "$SRC" \
    -o "$OUTPUT"

echo
echo "Build completed successfully"
echo

file "$OUTPUT"