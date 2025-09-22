#!/usr/bin/env bash
set -euo pipefail

# Usage: ./mergePDFs.sh [INPUT_DIR] [TEMP_OUTPUT_FILE] [FINAL_OUTPUT_FILE] 
INPUT_DIR="${1:-output}"
OUTPUT_FILE="${2:-merged.pdf}"
OUTPUT_FILE_NUMBERED="${3:-final.pdf}"

if ! command -v qpdf >/dev/null 2>&1; then
  echo "Error: qpdf is not installed. macOS: brew install qpdf, Ubuntu: sudo apt-get install qpdf"
  exit 1
fi

shopt -s nullglob
pdf_paths=( "$INPUT_DIR"/*.pdf )
if [ ${#pdf_paths[@]} -eq 0 ]; then
  echo "No PDFs found in: $INPUT_DIR"
  exit 1
fi

# Sort alphanumerically by filename
tmp_list="$(mktemp)"
for f in "${pdf_paths[@]}"; do
  printf '%s\n' "$(basename "$f")" >> "$tmp_list"
done
LC_ALL=C sort "$tmp_list" -o "$tmp_list"

# Rebuild full paths in sorted order
mapfile -t ordered_paths < <(while IFS= read -r base; do
  printf '%s\n' "$INPUT_DIR/$base"
done < "$tmp_list")
rm -f "$tmp_list"

echo "Merging ${#ordered_paths[@]} files into: $OUTPUT_FILE"
# --empty + --pages performs a pure concatenation without altering content
qpdf --empty --pages "${ordered_paths[@]}" -- "$OUTPUT_FILE"
echo "Done: $OUTPUT_FILE"

# pip install --upgrade pip   
# pip install pypdf reportlab     

source .venv/bin/activate

python3 number_pdf.py "$OUTPUT_FILE" "$OUTPUT_FILE_NUMBERED"

# deactivate
