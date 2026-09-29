#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)

BINARY="$PROJECT_DIR/builds/env-info-native-host"
LOG_DIR="$PROJECT_DIR/logs"
REPORT="$LOG_DIR/native-host-analysis.txt"

if [[ ! -f "$BINARY" ]]; then
    echo "Error: executable '$BINARY' not found. Build it first." >&2
    exit 1
fi

for tool in file readelf ldd size strings stat tee; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Error: required tool '$tool' not found." >&2
        exit 1
    fi
done

mkdir -p "$LOG_DIR"

{
    echo "Native host executable analysis"
    echo "Executable: $BINARY"
    echo

    echo "File type"
    file "$BINARY"
    echo

    echo "ELF header: readelf -hW"
    readelf -hW "$BINARY"
    echo

    echo "Program headers: readelf -lW"
    readelf -lW "$BINARY"
    echo

    echo "Dynamic section: readelf -dW"
    readelf -dW "$BINARY"
    echo

    echo "Symbol versions: readelf -VW"
    readelf -VW "$BINARY"
    echo

    echo "Shared libraries: ldd"
    ldd "$BINARY"
    echo

    echo "Code and data sizes: size"
    size "$BINARY"
    echo

    echo "File size"
    stat -c '%n: %s bytes' "$BINARY"
    echo

    echo "Printable strings: strings -a"
    strings -a "$BINARY"
    echo
} 2>&1 | tee "$REPORT"

echo "Analysis saved to: ${REPORT}"