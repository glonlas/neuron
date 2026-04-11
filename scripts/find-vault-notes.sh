#!/usr/bin/env bash
# Find vault notes modified since a cutoff.
#
# Usage:
#   find-vault-notes.sh                  # since last scan (or 7d if first run)
#   find-vault-notes.sh --since 3d       # last N days
#   find-vault-notes.sh --since 3h       # last N hours
#   find-vault-notes.sh --since 2026-04-01  # since a specific date
#   find-vault-notes.sh --all            # entire vault
#
# Output (tab-separated, one per line):
#   relative_path \t mod_date \t word_count
#
# Excludes: LLM-Wiki/, LLM-Wiki-Sources/, .obsidian/, Untitled*, files < 50 words
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/_config.sh"

CLEANUP_REF=""
cleanup() { [ -n "$CLEANUP_REF" ] && rm -f "$CLEANUP_REF"; }
trap cleanup EXIT

# --- Parse args ---
SINCE=""
ALL=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --since) SINCE="$2"; shift 2;;
        --all)   ALL=true; shift;;
        *)       shift;;
    esac
done

# --- Build find command into a temp file of paths ---
FIND_ARGS=()

if [ "$ALL" = false ]; then
    if [ -n "$SINCE" ]; then
        CLEANUP_REF=$(mktemp)
        if [[ "$SINCE" =~ ^([0-9]+)d$ ]]; then
            touch -t "$(date -v-"${BASH_REMATCH[1]}"d +%Y%m%d%H%M.%S)" "$CLEANUP_REF"
        elif [[ "$SINCE" =~ ^([0-9]+)h$ ]]; then
            touch -t "$(date -v-"${BASH_REMATCH[1]}"H +%Y%m%d%H%M.%S)" "$CLEANUP_REF"
        else
            TS=$(echo "$SINCE" | sed 's/-//g')
            touch -t "${TS}0000.00" "$CLEANUP_REF"
        fi
        FIND_ARGS=(-newer "$CLEANUP_REF")
    elif [ -f "${CONFIG_DIR}/last-scan" ]; then
        FIND_ARGS=(-newer "${CONFIG_DIR}/last-scan")
    else
        CLEANUP_REF=$(mktemp)
        touch -t "$(date -v-7d +%Y%m%d%H%M.%S)" "$CLEANUP_REF"
        FIND_ARGS=(-newer "$CLEANUP_REF")
    fi
fi

# Collect matching paths into a temp file to avoid subshell issues
PATHFILE=$(mktemp)
trap "rm -f '$PATHFILE' ; cleanup" EXIT

find "$VAULT" -name "*.md" \
    ${FIND_ARGS[@]+"${FIND_ARGS[@]}"} \
    -not -path "*/LLM-Wiki/*" \
    -not -path "*/LLM-Wiki-Sources/*" \
    -not -path "*/.obsidian/*" \
    -not -name "Untitled*" \
    2>/dev/null | sort > "$PATHFILE"

# Process each path
while IFS= read -r f; do
    [ -z "$f" ] && continue
    wc_count=$(wc -w < "$f" 2>/dev/null | tr -d ' ')
    [ "${wc_count:-0}" -lt 50 ] && continue
    rel="${f#"${VAULT}"/}"
    mod=$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$f" 2>/dev/null || echo "unknown")
    printf "%s\t%s\t%s\n" "$rel" "$mod" "$wc_count"
done < "$PATHFILE"
