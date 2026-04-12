#!/usr/bin/env bash
# Check if a source has already been imported.
#
# Usage:
#   check-duplicate.sh --url "https://example.com/article"
#   check-duplicate.sh --vault-path "Work/Engineering/Some Note.md"
#   check-duplicate.sh --title "Some Article Title"
#
# Output:
#   If duplicate found:  DUPLICATE \t filepath \t imported_date
#   If no duplicate:     (nothing, exit 1)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/_config.sh"

URL=""
VAULT_PATH=""
TITLE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --url)        URL="$2"; shift 2;;
        --vault-path) VAULT_PATH="$2"; shift 2;;
        --title)      TITLE="$2"; shift 2;;
        *)            shift;;
    esac
done

if [ ! -d "$SOURCES" ]; then
    exit 1
fi

search_in_sources() {
    local pattern="$1"
    # Use -F for fixed-string matching (no regex interpretation of URLs)
    grep -Frl "$pattern" "$SOURCES" --include="*.md" 2>/dev/null | while IFS= read -r f; do
        imported=$(sed -n 's/^imported: *\(.*\)/\1/p' "$f" | head -1)
        printf "DUPLICATE\t%s\t%s\n" "$f" "${imported:-unknown}"
    done
}

if [ -n "$URL" ]; then
    pattern="$URL"
elif [ -n "$VAULT_PATH" ]; then
    pattern="vault_path: \"${VAULT_PATH}\""
elif [ -n "$TITLE" ]; then
    pattern="title: \"${TITLE}\""
else
    echo "ERROR: Provide --url, --vault-path, or --title" >&2
    exit 2
fi

# Single search: capture output, print it, and set exit code
output=$(search_in_sources "$pattern")
if [ -n "$output" ]; then
    echo "$output"
else
    exit 1
fi
