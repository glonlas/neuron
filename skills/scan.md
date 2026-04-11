---
name: wiki-scan
description: >
  Scan the Obsidian vault for recently modified or created notes and
  auto-import and ingest them. Designed for daily ingestion of notes you
  wrote yourself. Tracks last scan time in ~/.llm-wiki/last-scan so each
  run only picks up what's new. Triggers on: wiki scan.
---

# Wiki Scan

Scan the vault for notes modified since the last scan, import them as sources, and ingest them through the identity filter. This is the daily-driver command for turning your own writing into wiki knowledge.

## Pre-flight

1. Read `CONFIG_DIR/config.yaml` for vault path.
2. Read `CONFIG_DIR/last-scan` for the timestamp of the last scan (a single ISO datetime line, e.g. `2026-04-11T09:00:00`). If the file doesn't exist, treat it as "never scanned" and ask the user for a lookback window (default: 7 days).

## Parsing the command

| Command | Behaviour |
|---------|-----------|
| `wiki scan` | Since last scan (or 7 days if first run) |
| `wiki scan --since 3d` | Last N days (d = days, h = hours) |
| `wiki scan --since 2026-04-01` | Since a specific date |
| `wiki scan --all` | Entire vault (ignores last-scan timestamp) |

## Step 1: Find candidate files

Run the script to find vault notes modified since the cutoff:

```sh
# Default: since last scan (or 7 days if first run)
SKILL_DIR/scripts/find-vault-notes.sh

# With --since flag
SKILL_DIR/scripts/find-vault-notes.sh --since 3d
SKILL_DIR/scripts/find-vault-notes.sh --since 2026-04-01

# Entire vault
SKILL_DIR/scripts/find-vault-notes.sh --all
```

Pass through any `--since` or `--all` flags from the user's command.

Output is tab-separated: `relative_path \t mod_date \t word_count`, one per line.
The script already excludes: LLM-Wiki/, LLM-Wiki-Sources/, .obsidian/, Untitled*, and files < 50 words.

If output is empty, inform the user: "No modified vault notes found since last scan."

## Step 3: Show the candidate list and confirm

Present the list of files found before doing anything:

```
Found 4 notes modified since 2026-04-10T08:30:00:

  Work/Engineering/Event Sourcing Research.md   (modified 2026-04-11 09:15)
  Learning/Languages/Lang Mandarin.md           (modified 2026-04-11 07:42)
  Cooking - Recipes/Miso Ramen.md               (modified 2026-04-10 21:05)
  Personal/Health/Sleep Tracking.md             (modified 2026-04-10 19:30)

Import and ingest all? [Y/n/select]
```

- `Y` or Enter → import all
- `n` → abort
- `select` → show numbered list, user picks which ones to include

## Step 4: Import each file

For each confirmed file, import it using the same logic as `wiki add` (file mode):
- Read the file content.
- Save to `SOURCES/{year}/{date}-{slug}.md` with frontmatter:
  ```yaml
  source_type: vault-note
  source_url: null
  vault_path: "Work/Engineering/Event Sourcing Research.md"
  imported: {today}
  ingested: false
  ```
- The slug is derived from the vault-relative path, e.g. `work-engineering-event-sourcing-research`.

Skip any file already imported — check using:
```sh
SKILL_DIR/scripts/check-duplicate.sh --vault-path "Work/Engineering/Some Note.md"
```
Exit code 0 = already imported (skip). Exit code 1 = new (import it).

## Step 5: Ingest

Run the ingest process (same as `wiki ingest`) on all newly imported sources:
- Score each against `CONFIG_DIR/filter-identity.md`.
- Create or update wiki pages for sources above the threshold.
- Skip (but mark ingested) those below the threshold.

## Step 6: Update last-scan timestamp

Write the current datetime to `CONFIG_DIR/last-scan`:

```
2026-04-11T09:32:00
```

This ensures the next `wiki scan` only picks up notes modified after this run.

## Step 7: Report

```
Scan complete — 2026-04-11T09:32:00

Scanned: 4 vault notes
Imported: 3 (1 already imported, skipped)
Ingested: 3
  ✓ Work/Engineering/Event Sourcing Research.md    → Created: LLM-Wiki/Concepts/Event Sourcing.md
  ✓ Cooking - Recipes/Miso Ramen.md               → Created: LLM-Wiki/Recipes/Miso Ramen.md
  ✗ Personal/Health/Sleep Tracking.md             → Skipped (score: 0.12, below threshold)

Next scan will pick up notes modified after: 2026-04-11T09:32:00
```
