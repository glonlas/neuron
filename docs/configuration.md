# Configuration

All user-specific configuration lives in `~/.llm-wiki/` — **outside the repo**. This keeps the skill reusable and shareable.

## Config files

| File | Purpose |
|------|---------|
| `~/.llm-wiki/config.yaml` | Wiki vault path, user vaults to scan, and settings |
| `~/.llm-wiki/filter-identity.md` | Your identity prompt: who this wiki is for and what matters |
| `~/.llm-wiki/query-log.md` | Query history, used by `wiki filter evolve` |
| `~/.llm-wiki/last-scan` | Timestamp of last `wiki scan` run |

`make install` copies example templates from `schema/*.example.*` into `~/.llm-wiki/` on first run. Existing files are never overwritten.

## config.yaml

```yaml
# The vault where wiki pages and sources are written
vault_path: "~/path/to/your/wiki-vault"

# Your personal note vaults that wiki scan reads from
user_vaults:
  - "~/path/to/your/main-notes-vault"
  - "~/path/to/another-vault"   # add as many as needed

# Customizable folder names (defaults shown)
wiki_folder: "LLM-Wiki"
sources_folder: "LLM-Wiki-Sources"

# Page types and scoring
page_types:
  - entity
  - concept
  - topic
  - recipe
  - comparison

tag_prefix: "llm-wiki"
min_relevance_score: 0.4
```

---

## Identity filter

### Generating your filter-identity.md

The fastest way to seed a personalized `filter-identity.md` is to ask an LLM what it already knows about you from your conversation history. Paste this prompt into ChatGPT (or any LLM you've been talking to):

```
Based on everything you know about me from our conversations — my job, projects,
interests, goals, and the topics I regularly ask about — please generate a
filter-identity.md file for my personal LLM Wiki.

Be specific and honest. The more precise the identity, the sharper the filtering.

Structure:

# Identity Filter

## Who is this wiki for?
[2-3 sentences: my role, primary domains, key interests]

## What matters (scoring dimensions)

| Dimension | Weight | Description |
|-----------|--------|-------------|
[6-9 rows tailored to me, weights summing to 1.0]

## Minimum relevance threshold
Score: **0.4** out of 1.0

## Scoring instructions
[Brief guidance with a concrete example using my domains]

## Evolution log
*No changes yet.*

Make the dimensions specific to what I actually care about. Weights should reflect
how central each domain is to my life and work.
```

Save the output to `~/.llm-wiki/filter-identity.md`. Alternatively, `wiki bootstrap` will draft it automatically from your vault structure.

### How the filter works

The filter defines scoring dimensions and weights. Each source is scored 0-1 against each dimension; the weighted sum is compared against a minimum threshold (default: 0.4). Sources below the threshold are marked ingested but don't get wiki pages — they stay in `LLM-Wiki-Sources/` for reference without cluttering the wiki.

Run `wiki filter evolve` periodically to tune weights based on what you actually query and link to. All filter changes require your approval and apply to future ingests only — existing pages are never retroactively removed.
