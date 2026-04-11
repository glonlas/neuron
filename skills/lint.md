---
name: wiki-lint
description: >
  Health check the LLM Wiki. Detects orphan sources, broken wikilinks, missing
  frontmatter, stale pages, duplicates, and index drift. Outputs a report with
  suggested fixes but does not auto-apply. Triggers on: wiki lint.
---

# Wiki Lint

Audit the LLM Wiki for structural issues and produce a health report. Does NOT auto-fix — presents findings for user approval.

## Pre-flight

1. Read `CONFIG_DIR/config.yaml` for paths.
2. Read `WIKI/_index.md` to get the current page listing.

## Checks

Run all checks and collect findings into categories.

### 1. Orphan Sources

Find sources in `SOURCES/` where `ingested: true` but no wiki page references them in its `sources` frontmatter.

- Read source files' `wiki_pages` field. If empty but `ingested: true` and `relevance_score >= threshold`, flag as orphan.
- **Severity**: Low (source was ingested but might have been skipped intentionally).
- **Suggested fix**: Re-run ingest on the source, or manually link it to a relevant wiki page.

### 2. Broken Wikilinks

Scan all wiki page content and frontmatter for `[[...]]` wikilinks. For each:
- Check if the target file exists in the vault.
- Flag any link pointing to a non-existent file.

- **Severity**: Medium (broken navigation).
- **Suggested fix**: Create the missing page, fix the link, or remove the dead reference.

### 3. Missing Frontmatter

Every wiki page MUST have these frontmatter fields: `title`, `type`, `created`, `updated`, `sources`, `tags`.

Scan all files in `WIKI/` (excluding `_index.md`) and flag any missing required fields.

- **Severity**: Medium (breaks Obsidian Bases views and filter evolution).
- **Suggested fix**: Add the missing fields.

### 4. Stale Pages

Pages where `updated` is more than 90 days old AND whose sources have newer versions or related sources were imported since.

- Compare page `updated` date against import dates of sources in the same domain.
- **Severity**: Low (content may still be accurate).
- **Suggested fix**: Re-ingest relevant sources or manually review.

### 5. Duplicate Detection

Find wiki pages that likely cover the same thing:
- Same or very similar titles (e.g., "FastAPI" and "Fast API").
- Pages of the same type with overlapping `aliases`.
- Multiple entity pages for the same subject.

- **Severity**: High (fragments knowledge, confuses queries).
- **Suggested fix**: Merge the pages, keeping the more complete one.

### 6. Index Drift

Compare `_index.md` entries against actual files in `WIKI/{Type}/`:
- Pages listed in index but not on disk → remove from index.
- Pages on disk but not in index → add to index.

- **Severity**: Medium (index is the query entry point).
- **Suggested fix**: Regenerate the affected index sections.

### 7. Semantic Type Errors

Check if pages are in the correct type folder:
- A page in `Entities/` that reads like a concept (no specific instance, describes an abstract idea).
- A page in `Concepts/` that is actually about a specific tool.
- A comparison page without explicit comparison axes in the content.

- **Severity**: Low (affects browsing and Bases views).
- **Suggested fix**: Move to the correct folder and update type frontmatter.

### 8. Source Integrity

Check source files in `SOURCES/`:
- Sources missing required frontmatter fields (`title`, `source_type`, `imported`, `ingested`).
- Sources where `ingested: false` for more than 30 days (forgotten imports).

- **Severity**: Low–Medium.
- **Suggested fix**: Fix frontmatter, or run ingest on stale pending sources.

## Report Format

```markdown
# Wiki Lint Report — {today}

## Summary
- Total wiki pages: {count}
- Total sources: {count}
- Issues found: {count}

## Critical (fix now)
{list of high-severity issues}

## Warnings (fix soon)
{list of medium-severity issues}

## Info (fix when convenient)
{list of low-severity issues}

## Details

### Broken Wikilinks
| Page | Broken Link | Suggested Fix |
|------|-------------|---------------|
| ... | ... | ... |

### Missing Frontmatter
| Page | Missing Fields |
|------|---------------|
| ... | ... |

### Duplicates
| Page A | Page B | Similarity |
|--------|--------|-----------|
| ... | ... | ... |

### Index Drift
| Issue | Page | Action |
|-------|------|--------|
| Missing from index | ... | Add |
| Not on disk | ... | Remove from index |
```

## Post-Report

After presenting the report:
1. Ask the user which issues they'd like to fix.
2. Apply fixes only for the issues the user approves.
3. Re-run the affected checks to confirm fixes.

Do NOT silently fix anything. The wiki is the user's knowledge base — they decide what changes are acceptable.
