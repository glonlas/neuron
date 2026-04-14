---
name: neuron-scan
description: >
  Scan all user_vaults for recently modified notes and auto-import/ingest
  them into the wiki. Designed for daily ingestion of notes you wrote yourself.
  Tracks last scan time in ~/.agents-neuron/last-scan so each run only picks up
  what's new. Triggers on: neuron scan.
---

# Wiki Scan

Scan all configured `user_vaults` for notes modified since the last scan, import them as sources, and ingest them through the identity filter. This is the daily-driver command for turning your own writing into wiki knowledge.

## Pre-flight

The script handles all timing logic. No manual timestamp reading needed.

## Parsing the command

| Command | Behaviour |
|---------|-----------|
| `neuron scan` | Since last scan (or 7 days if first run) |
| `neuron scan --since 3d` | Last N days (d = days, h = hours) |
| `neuron scan --since 2026-04-01` | Since a specific date |
| `neuron scan --all` | All notes in user_vaults (ignores last-scan) |

## Step 1: Find candidate files

Run the script, passing through any flags from the user's command:

```sh
SKILL_DIR/scripts/find-vault-notes.sh
SKILL_DIR/scripts/find-vault-notes.sh --since 3d
SKILL_DIR/scripts/find-vault-notes.sh --since 2026-04-01
SKILL_DIR/scripts/find-vault-notes.sh --all
```

Output is tab-separated, one file per line:
```
absolute_path \t vault_name \t relative_path \t mod_date \t word_count
```

The script reads `user_vaults` from config automatically. It excludes `.obsidian/`, `Untitled*`, and files < 50 words. If no `user_vaults` are configured it exits with an error.

If output is empty, inform the user: "No modified notes found in user_vaults since last scan."

## Step 2: Show the candidate list and confirm

Present the list grouped by vault before doing anything:

```
Found 4 notes modified since 2026-04-10T08:30:00:

  [My Notes]
  Work/Engineering/Event Sourcing Research.md   (2026-04-11 09:15, 340 words)
  Learning/Languages/Language Notes.md          (2026-04-11 07:42, 1362 words)
  Cooking/Miso Ramen.md                         (2026-04-10 21:05, 232 words)
  Personal/Health/Sleep Tracking.md             (2026-04-10 19:30, 88 words)

Import and ingest all? [Y/n/select]
```

- `Y` or Enter → import all
- `n` → abort
- `select` → show numbered list, user picks which to include

## Step 3: Import each file

For each confirmed file, check for duplicates first:
```sh
SKILL_DIR/scripts/check-duplicate.sh --vault-path "vault_name/relative_path"
```
Exit code 0 = already imported (skip). Exit code 1 = new (import it).

For new files, read the absolute_path content and save to:
`SOURCES/{year}/{YYYY-MM-DD}-{slug}.md`

Where slug is derived from the relative path: `work-engineering-event-sourcing-research`.

Source frontmatter:
```yaml
---
title: "Note Title"
source_type: vault-note
source_url: null
vault_name: "My Notes"
vault_path: "Work/Engineering/Event Sourcing Research.md"
imported: {today}
ingested: false
relevance_score: null
wiki_pages: []
---
```

Note: `vault_path` stores `vault_name/relative_path` so `check-duplicate.sh` can find it uniquely across multiple vaults.

## Step 4: Ingest

Run the ingest process on all newly imported sources:
- Score each against `CONFIG_DIR/filter-identity.md`.
- Create or update wiki pages for sources above the threshold.
- Skip (but mark ingested) those below the threshold.

## Step 5: Update last-scan timestamp

Write the current datetime to `CONFIG_DIR/last-scan`:
```
2026-04-11T09:32:00
```

## Step 6: Report

```
Scan complete — 2026-04-11T09:32:00

Vaults scanned: 1 (My Notes)
Notes found: 4 | Imported: 3 (1 duplicate skipped) | Ingested: 3

  ✓ Work/Engineering/Event Sourcing Research.md  → Created: Neuron/Concepts/Event Sourcing.md
  ✓ Cooking - Recipes/Miso Ramen.md              → Created: Neuron/Recipes/Miso Ramen.md
  ✗ Personal/Health/Sleep Tracking.md            → Skipped (score: 0.12, below threshold)

Next scan will pick up notes modified after: 2026-04-11T09:32:00
```
