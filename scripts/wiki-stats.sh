#!/usr/bin/env bash
# Compute wiki statistics.
#
# Output (key=value, one per line):
#   entities=3
#   concepts=5
#   topics=2
#   recipes=4
#   comparisons=1
#   total_pages=15
#   total_sources=22
#   pending_sources=3
#   ingested_sources=19
#   skipped_sources=7
#   avg_relevance=0.62
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/_config.sh"

count_md() {
    local dir="$1"
    if [ -d "$dir" ]; then
        find "$dir" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' '
    else
        echo 0
    fi
}

entities=$(count_md "${WIKI}/Entities")
concepts=$(count_md "${WIKI}/Concepts")
topics=$(count_md "${WIKI}/Topics")
recipes=$(count_md "${WIKI}/Recipes")
comparisons=$(count_md "${WIKI}/Comparisons")
total_pages=$((entities + concepts + topics + recipes + comparisons))

# Source stats
total_sources=0
pending_sources=0
ingested_sources=0
skipped_sources=0
score_sum=0
score_count=0

if [ -d "$SOURCES" ]; then
    while IFS= read -r f; do
        [ -z "$f" ] && continue
        total_sources=$((total_sources + 1))

        ingested=$(sed -n 's/^ingested: *\(.*\)/\1/p' "$f" | head -1)
        score=$(sed -n 's/^relevance_score: *\(.*\)/\1/p' "$f" | head -1)
        wiki_pages=$(sed -n 's/^wiki_pages: *\(.*\)/\1/p' "$f" | head -1)

        if [ "$ingested" = "false" ]; then
            pending_sources=$((pending_sources + 1))
        else
            ingested_sources=$((ingested_sources + 1))
            # Skipped = ingested but no wiki pages created
            if [ "$wiki_pages" = "[]" ] || [ -z "$wiki_pages" ]; then
                skipped_sources=$((skipped_sources + 1))
            fi
        fi

        # Accumulate scores for average (only non-null, non-zero)
        if [ -n "$score" ] && [ "$score" != "null" ] && [ "$score" != "0" ]; then
            # Use awk for float arithmetic
            score_sum=$(awk "BEGIN{printf \"%.4f\", $score_sum + $score}")
            score_count=$((score_count + 1))
        fi
    done < <(find "$SOURCES" -name "*.md" -type f 2>/dev/null | sort)
fi

if [ "$score_count" -gt 0 ]; then
    avg_relevance=$(awk "BEGIN{printf \"%.2f\", $score_sum / $score_count}")
else
    avg_relevance="n/a"
fi

cat <<EOF
entities=${entities}
concepts=${concepts}
topics=${topics}
recipes=${recipes}
comparisons=${comparisons}
total_pages=${total_pages}
total_sources=${total_sources}
pending_sources=${pending_sources}
ingested_sources=${ingested_sources}
skipped_sources=${skipped_sources}
avg_relevance=${avg_relevance}
EOF
