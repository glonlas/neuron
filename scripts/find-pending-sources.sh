#!/usr/bin/env bash
# Find source files with ingested: false
#
# Output (tab-separated, one per line):
#   filepath \t title \t word_count
#
# Exit 0 if found, exit 1 if none.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/_config.sh"

if [ ! -d "$SOURCES" ]; then
    echo "ERROR: Sources directory not found at ${SOURCES}" >&2
    exit 1
fi

found=0
grep -rl '^ingested: false' "$SOURCES" --include="*.md" 2>/dev/null | sort | while IFS= read -r f; do
    title=$(sed -n 's/^title: *"\{0,1\}\(.*[^"]\)"\{0,1\}$/\1/p' "$f" | head -1)
    title="${title:-$(basename "$f" .md)}"
    wc_count=$(wc -w < "$f" 2>/dev/null | tr -d ' ')
    printf "%s\t%s\t%s\n" "$f" "$title" "${wc_count:-0}"
    found=1
done

# grep -rl returns non-zero when nothing matches; the pipeline may swallow it.
# We re-check explicitly.
if ! grep -qrl '^ingested: false' "$SOURCES" --include="*.md" 2>/dev/null; then
    echo "No pending sources found." >&2
    exit 1
fi
