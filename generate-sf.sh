#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DBGEN="$ROOT/dbgen"
DATA_DIR="${SSB_DATA_DIR:-$ROOT/.local/data}"

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <scale-factor>"
    echo "Example: $0 1"
    exit 1
fi

SF="$1"
OUT="$DATA_DIR/sf${SF}"

if [[ ! "$SF" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "Error: invalid scale factor: $SF"
    exit 1
fi

if [[ -d "$OUT" ]] && find "$OUT" -type f -print -quit | grep -q .; then
    echo "Error: $OUT already contains data."
    echo "Remove it first if you want to regenerate it."
    exit 1
fi

mkdir -p "$OUT"

echo "Repository : $ROOT"
echo "Scale      : $SF"
echo "Output     : $OUT"
echo

cd "$DBGEN"

echo "==> Building dbgen"
make MACHINE=LINUX DATABASE=POSTGRESQL

echo "==> Cleaning old generator output"
rm -f ./*.tbl

echo "==> Generating SF${SF}"
./dbgen -s "$SF" -T a -f -v

echo "==> Moving generated data"
mv ./*.tbl "$OUT/"

echo
echo "==> Generated files:"
ls -lh "$OUT"

echo
echo "==> SHA-256:"
sha256sum "$OUT"/*.tbl
