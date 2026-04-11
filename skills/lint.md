---
name: wiki-lint
description: >
  Health check the LLM Wiki. Detects orphan sources, broken wikilinks, missing
  frontmatter, stale pages, duplicates, and index drift. Outputs a report with
  suggested fixes but does not auto-apply. Triggers on: wiki lint.
---

# Wiki Lint

Audit the LLM Wiki for structural issues and produce a health report. Does NOT auto-fix — presents findings for user approval.

## Step 1: Run Deterministic Checks (via script)

Run the lint script to get all file-system-level findings:

```sh
SKILL_DIR/scripts/lint-checks.sh
```

This runs 6 deterministic checks and outputs structured blocks:
- `=== ORPHAN_SOURCES ===` — ingested sources with score >= threshold but no wiki pages
- `=== BROKEN_WIKILINKS ===` — wiki page links pointing to non-existent files
- `=== MISSING_FRONTMATTER ===` — wiki pages missing required fields (title, type, created, updated, sources, tags)
- `=== INDEX_DRIFT ===` — pages on disk but not in _index.md, or dead links in _index.md
- `=== STALE_PENDING_SOURCES ===` — sources with `ingested: false` for 30+ days
- `=== SOURCE_INTEGRITY ===` — source files missing required frontmatter fields

You can also run individual checks:
```sh
SKILL_DIR/scripts/lint-checks.sh --check orphans
SKILL_DIR/scripts/lint-checks.sh --check broken-links
```

## Step 2: Run LLM-Only Checks

These checks require judgment and cannot be scripted:

### Semantic Type Errors
Read wiki pages and check if they are in the correct type folder:
- A page in `Entities/` that reads like a concept (describes an abstract idea, not a specific thing).
- A page in `Concepts/` that is actually about a specific tool.
- A comparison page without explicit comparison axes in the content.

### Duplicate Detection
Check for wiki pages that likely cover the same thing:
- Same or very similar titles (e.g., "FastAPI" and "Fast API").
- Pages of the same type with overlapping `aliases`.
- Multiple entity pages for the same subject.

## Step 3: Get Stats

Run:
```sh
SKILL_DIR/scripts/wiki-stats.sh
```

Output is `key=value` pairs: entities, concepts, topics, recipes, comparisons, total_pages, total_sources, pending_sources, ingested_sources, skipped_sources, avg_relevance.

## Step 4: Compile Report

Combine script output and LLM findings into a report:

```markdown
# Wiki Lint Report — {today}

## Summary
- Total wiki pages: {total_pages}
- Total sources: {total_sources} ({pending_sources} pending, {skipped_sources} skipped)
- Issues found: {count}

## Critical (fix now)
{high-severity: broken wikilinks, duplicates}

## Warnings (fix soon)
{medium-severity: missing frontmatter, index drift, semantic type errors}

## Info (fix when convenient)
{low-severity: orphan sources, stale pending sources}

## Details
{Detailed tables from script output, formatted as markdown}
```

## Step 5: Post-Report

After presenting the report:
1. Ask the user which issues they'd like to fix.
2. Apply fixes only for the issues the user approves.
3. When fixing source metadata, use: `SKILL_DIR/scripts/update-source-meta.sh <file> <flags>`
4. Re-run `SKILL_DIR/scripts/lint-checks.sh` on affected checks to confirm fixes.

Do NOT silently fix anything. The wiki is the user's knowledge base — they decide what changes are acceptable.
