#!/usr/bin/env bash
# Shared config loader — sourced by all llm-wiki scripts.
# Exports: CONFIG_DIR, VAULT, WIKI, SOURCES, MIN_SCORE
set -euo pipefail

CONFIG_DIR="${HOME}/.llm-wiki"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config not found at ${CONFIG_FILE}. Run 'make install' first." >&2
    exit 1
fi

# Parse vault_path — handles both quoted and unquoted values
VAULT=$(sed -n 's/^vault_path: *"\{0,1\}\(.*[^"]\)"\{0,1\}$/\1/p' "$CONFIG_FILE" | head -1)

if [ -z "$VAULT" ]; then
    echo "ERROR: vault_path not set in ${CONFIG_FILE}" >&2
    exit 1
fi

if [ ! -d "$VAULT" ]; then
    echo "ERROR: Vault not found at ${VAULT}" >&2
    exit 1
fi

WIKI="${VAULT}/LLM-Wiki"
SOURCES="${VAULT}/LLM-Wiki-Sources"
MIN_SCORE=$(awk '/^min_relevance_score:/{print $2}' "$CONFIG_FILE")
MIN_SCORE="${MIN_SCORE:-0.4}"
