#!/usr/bin/env bash
# Shared config loader — sourced by all Agents Neuron scripts.
# Exports: CONFIG_DIR, VAULT, WIKI, SOURCES, MIN_SCORE, PAGE_TYPES,
#          SED_INPLACE (array)
# Functions: get_user_vaults, portable_date_ago, portable_stat_mtime
set -euo pipefail

# ── Platform detection ───────────────────────────────────────────
if [[ "$OSTYPE" == darwin* ]]; then
    _IS_MACOS=true
else
    _IS_MACOS=false
fi

# sed -i '' (macOS) vs sed -i (GNU)
if $_IS_MACOS; then
    SED_INPLACE=(-i '')
else
    SED_INPLACE=(-i)
fi

# portable_date_ago <N> <unit>
#   unit: d (days) or h (hours)
#   Prints a touch-compatible timestamp: YYYYMMDDHHmm.SS
portable_date_ago() {
    local n="$1" unit="$2"
    if $_IS_MACOS; then
        case "$unit" in
            d) date -v-"${n}d" +%Y%m%d%H%M.%S ;;
            h) date -v-"${n}H" +%Y%m%d%H%M.%S ;;
        esac
    else
        case "$unit" in
            d) date -d "${n} days ago" +%Y%m%d%H%M.%S ;;
            h) date -d "${n} hours ago" +%Y%m%d%H%M.%S ;;
        esac
    fi
}

# portable_stat_mtime <file>
#   Prints modification time as "YYYY-MM-DD HH:MM"
portable_stat_mtime() {
    if $_IS_MACOS; then
        stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$1" 2>/dev/null || echo "unknown"
    else
        stat -c '%y' "$1" 2>/dev/null | cut -d. -f1 | sed 's/\(.*\):.*/\1/' || echo "unknown"
    fi
}

# portable_date_days_ago <N>
#   Prints YYYY-MM-DD for N days ago (used by lint stale-sources check)
portable_date_days_ago() {
    local n="$1"
    if $_IS_MACOS; then
        date -v-"${n}d" +%Y-%m-%d
    else
        date -d "${n} days ago" +%Y-%m-%d
    fi
}

# ── Config loading ───────────────────────────────────────────────
CONFIG_DIR="${HOME}/.agents-neuron"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config not found at ${CONFIG_FILE}. Run 'make install' first." >&2
    exit 1
fi

# Parse vault_path — handles both quoted and unquoted values
VAULT=$(sed -n 's/^vault_path: *"\{0,1\}\(.*[^"]\)"\{0,1\}$/\1/p' "$CONFIG_FILE" | head -1)
# Expand ~ to $HOME
VAULT="${VAULT/#\~/$HOME}"

if [ -z "$VAULT" ]; then
    echo "ERROR: vault_path not set in ${CONFIG_FILE}" >&2
    exit 1
fi

if [ ! -d "$VAULT" ]; then
    echo "ERROR: Vault not found at ${VAULT}" >&2
    exit 1
fi

# Read folder names from config, with defaults
_strip_quotes() { sed 's/^"//;s/"$//;s/^'\''//;s/'\''$//'; }
WIKI_FOLDER=$(awk '/^wiki_folder:/{print $2}' "$CONFIG_FILE" | _strip_quotes)
WIKI_FOLDER="${WIKI_FOLDER:-Agents-Neuron}"
SOURCES_FOLDER=$(awk '/^sources_folder:/{print $2}' "$CONFIG_FILE" | _strip_quotes)
SOURCES_FOLDER="${SOURCES_FOLDER:-Neuron-Sources}"

WIKI="${VAULT}/${WIKI_FOLDER}"
SOURCES="${VAULT}/${SOURCES_FOLDER}"

MIN_SCORE=$(awk '/^min_relevance_score:/{print $2}' "$CONFIG_FILE")
MIN_SCORE="${MIN_SCORE:-0.4}"

# Parse page_types list from config, default to standard set
_parse_page_types() {
    awk '
        /^page_types:/ { found=1; next }
        found && /^[[:space:]]*-[[:space:]]/ {
            line = $0
            gsub(/^[[:space:]]*-[[:space:]]*"?/, "", line)
            gsub(/"?[[:space:]]*$/, "", line)
            if (line != "") print line
        }
        found && /^[^[:space:]-]/ { exit }
    ' "$CONFIG_FILE"
}
PAGE_TYPES=$(_parse_page_types)
if [ -z "$PAGE_TYPES" ]; then
    PAGE_TYPES="entity
concept
topic
recipe
comparison"
fi

# Capitalize first letter and pluralize: entity → Entities, concept → Concepts
_type_to_dir() {
    local t="$1"
    local first upper word plural
    first="${t:0:1}"
    upper=$(echo "$first" | tr '[:lower:]' '[:upper:]')
    word="${upper}${t:1}"
    case "$word" in
        *[^aeiouAEIOU]y)  plural="${word%y}ies" ;;   # consonant+y → ies (entity→Entities)
        *[sxz]|*[sc]h)    plural="${word}es" ;;       # s/x/z/sh/ch → es (class→Classes)
        *fe)               plural="${word%fe}ves" ;;   # fe → ves (knife→Knives)
        *[^aeiouAEIOU]f)  plural="${word%f}ves" ;;    # consonant+f → ves (leaf→Leaves)
        *)                 plural="${word}s" ;;
    esac
    echo "$plural"
}

# Parse user_vaults list — prints one path per line, strips quotes.
# YAML format expected:
#   user_vaults:
#     - "/path/to/vault"
#     - "/path/to/another"
get_user_vaults() {
    awk '
        /^user_vaults:/ { found=1; next }
        found && /^[[:space:]]*-[[:space:]]/ {
            line = $0
            gsub(/^[[:space:]]*-[[:space:]]*"?/, "", line)
            gsub(/"?[[:space:]]*$/, "", line)
            if (line != "") print line
        }
        found && /^[^[:space:]-]/ { exit }
    ' "$CONFIG_FILE" | while IFS= read -r vault; do
        # Expand ~ to $HOME
        echo "${vault/#\~/$HOME}"
    done
}
