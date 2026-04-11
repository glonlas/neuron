#!/usr/bin/env bash
# Update frontmatter fields in a source file.
#
# Usage:
#   update-source-meta.sh <file> [--ingested true|false] [--score 0.78] [--wiki-pages '["[[page1]]","[[page2]]"]']
#
# Only updates fields that are passed. Preserves all other content.
set -euo pipefail

FILE="$1"; shift

if [ ! -f "$FILE" ]; then
    echo "ERROR: File not found: ${FILE}" >&2
    exit 1
fi

INGESTED=""
SCORE=""
WIKI_PAGES=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ingested)   INGESTED="$2"; shift 2;;
        --score)      SCORE="$2"; shift 2;;
        --wiki-pages) WIKI_PAGES="$2"; shift 2;;
        *)            shift;;
    esac
done

# macOS sed requires -i '' ; GNU sed uses -i
SED_INPLACE=(-i '')

if [ -n "$INGESTED" ]; then
    sed "${SED_INPLACE[@]}" "s/^ingested: .*/ingested: ${INGESTED}/" "$FILE"
fi

if [ -n "$SCORE" ]; then
    sed "${SED_INPLACE[@]}" "s/^relevance_score: .*/relevance_score: ${SCORE}/" "$FILE"
fi

if [ -n "$WIKI_PAGES" ]; then
    # Replace the wiki_pages line. Handles both [] and existing lists.
    sed "${SED_INPLACE[@]}" "s|^wiki_pages: .*|wiki_pages: ${WIKI_PAGES}|" "$FILE"
fi

echo "OK: ${FILE}"
