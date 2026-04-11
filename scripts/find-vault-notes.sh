#!/usr/bin/env bash
# Find notes modified since a cutoff across all user_vaults in config.
#
# Usage:
#   find-vault-notes.sh                  # since last scan (or 7d if first run)
#   find-vault-notes.sh --since 3d       # last N days
#   find-vault-notes.sh --since 3h       # last N hours
#   find-vault-notes.sh --since 2026-04-01  # since a specific date
#   find-vault-notes.sh --all            # no time filter
#
# Output (tab-separated, one per line):
#   absolute_path \t vault_name \t relative_path \t mod_date \t word_count
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

# --- Build -newer reference file ---
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

# --- Get user vaults ---
PATHFILE=$(mktemp)
trap "rm -f '$PATHFILE'; cleanup" EXIT

VAULT_COUNT=0
while IFS= read -r user_vault; do
    [ -z "$user_vault" ] && continue
    if [ ! -d "$user_vault" ]; then
        echo "WARN: user vault not found, skipping: ${user_vault}" >&2
        continue
    fi
    VAULT_COUNT=$((VAULT_COUNT + 1))
    vault_name="$(basename "$user_vault")"

    find "$user_vault" -name "*.md" \
        ${FIND_ARGS[@]+"${FIND_ARGS[@]}"} \
        -not -path "*/.obsidian/*" \
        -not -name "Untitled*" \
        2>/dev/null | sort | while IFS= read -r f; do
        printf "%s\t%s\n" "$f" "$vault_name"
    done >> "$PATHFILE"
done < <(get_user_vaults)

if [ "$VAULT_COUNT" -eq 0 ]; then
    echo "ERROR: No user_vaults configured in ${CONFIG_FILE}." >&2
    echo "       Add at least one vault under 'user_vaults:' to use wiki scan." >&2
    exit 1
fi

# --- Filter and output ---
while IFS=$'\t' read -r f vault_name; do
    [ -z "$f" ] && continue
    wc_count=$(wc -w < "$f" 2>/dev/null | tr -d ' ')
    [ "${wc_count:-0}" -lt 50 ] && continue
    vault_root="$(dirname "$f")"
    # Walk up to find the vault root by matching vault_name
    abs_vault=""
    candidate="$f"
    while [ "$candidate" != "/" ]; do
        candidate="$(dirname "$candidate")"
        if [ "$(basename "$candidate")" = "$vault_name" ]; then
            abs_vault="$candidate"
            break
        fi
    done
    if [ -z "$abs_vault" ]; then
        abs_vault="$(dirname "$f")"
    fi
    rel="${f#"${abs_vault}"/}"
    mod=$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$f" 2>/dev/null || echo "unknown")
    printf "%s\t%s\t%s\t%s\t%s\n" "$f" "$vault_name" "$rel" "$mod" "$wc_count"
done < "$PATHFILE"
