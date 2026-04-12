# Neuron

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg)]()
[![Claude Code](https://img.shields.io/badge/Claude%20Code-skill-blueviolet.svg)]()

A Claude Code skill that builds a personal, compounding knowledge wiki inside your Obsidian vault. Import sources from URLs, notes, or text — Neuron filters them through your identity profile, transforms qualifying content into structured wiki pages, and keeps the whole thing healthy over time.

Inspired by [Karpathy's LLM Wiki concept](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) and [Baljanak's identity-aware learning filter](https://gist.github.com/baljanak/f233d3e321d353d34f2f6663369b3105). Built from scratch.

---

## How it works

```
Your vaults (personal notes)     ─┐
External URLs / text              ├→ wiki add  →  LLM-Wiki-Sources/{year}/{date}-{slug}.md
Pasted content                    ┘                   (raw, immutable)
                                         ↓
                                 wiki ingest   →  scores against identity filter
                                                    below threshold → stays in sources only
                                                    above threshold → LLM-Wiki/{Type}/Page.md
                                         ↓
                                 wiki query    →  synthesizes answers with citations
                                 wiki lint     →  health checks
                                 wiki filter   →  tune relevance over time
```

The wiki lives inside your Obsidian vault as normal markdown — wikilinks, tags, graph view, and sync all work out of the box.

---

## Prerequisites

- [Claude Code](https://claude.ai/code) (CLI, desktop app, or IDE extension)
- [Obsidian](https://obsidian.md/) vault (or any folder — Obsidian is optional but recommended)
- Bash 4+ (macOS and Linux supported)

---

## Install

```sh
# 1. Clone the repo
git clone https://github.com/glonlas/neuron.git
cd neuron

# 2. Install skill symlinks + seed personal config
make install

# 3. Edit your vault path
#    Open ~/.llm-wiki/config.yaml and set vault_path

# 4. Initialize the vault structure (in Claude Code)
wiki bootstrap
```

To validate your setup:

```sh
scripts/doctor.sh
```

To remove:

```sh
make uninstall
```

---

## Personal config

All user-specific configuration lives in `~/.llm-wiki/` — **outside this repo**. This keeps the skill reusable and safe to publish.

| File | Purpose |
|------|---------|
| `~/.llm-wiki/config.yaml` | Wiki vault path, user vaults to scan, and settings |
| `~/.llm-wiki/filter-identity.md` | Your identity prompt: who this wiki is for and what matters |
| `~/.llm-wiki/query-log.md` | Query history, used by `wiki filter evolve` |
| `~/.llm-wiki/last-scan` | Timestamp of last `wiki scan` run |

The two key fields in `config.yaml`:

```yaml
# The vault where wiki pages and sources are written
vault_path: "~/path/to/your/wiki-vault"

# Your personal note vaults that wiki scan reads from
user_vaults:
  - "~/path/to/your/main-notes-vault"
  - "~/path/to/another-vault"   # add as many as needed
```

`make install` copies example templates from `schema/*.example.*` into `~/.llm-wiki/` on first run. Existing files are never overwritten.

---

## Commands

| Command | What it does |
|---------|-------------|
| `wiki bootstrap` | One-time setup: creates vault folders and drafts your identity filter |
| `wiki scan` | Scan vault for recently modified notes and auto-import/ingest them |
| `wiki scan --since 3d` | Scan notes modified in the last N days (or `--since YYYY-MM-DD`) |
| `wiki scan --all` | Scan the entire vault regardless of last scan time |
| `wiki add <url\|text\|file>` | Manually import a single source into `LLM-Wiki-Sources/` |
| `wiki ingest` | Process all pending sources through the filter; create wiki pages |
| `wiki query <question>` | Synthesize an answer from wiki pages with inline citations |
| `wiki lint` | Health check: broken links, orphans, duplicates, stale pages |
| `wiki filter show` | Display current identity filter and scoring dimensions |
| `wiki filter score <source>` | Manually score a source without ingesting it |
| `wiki filter evolve` | Analyze usage patterns and propose filter weight adjustments |

---

## Daily usage

### Your own notes → wiki (daily)

Run this each morning or after a writing session to pull your own vault notes into the wiki:

```
wiki scan
```

It finds every note modified since the last scan, shows you the list, asks for confirmation, then imports and ingests them. Notes that score below your relevance threshold are skipped — only what actually matters to you becomes a wiki page.

First run (no prior scan): defaults to the last 7 days. Override with:

```
wiki scan --since 7d
wiki scan --since 2026-04-01
wiki scan --all        # entire vault, use once on first setup
```

### External content → wiki (as needed)

When you read something worth keeping — an article, a thread, a doc:

```
wiki add https://some-article.com
wiki ingest
```

Or import multiple sources at once, then batch-ingest:

```
wiki add https://article-1.com
wiki add https://article-2.com
wiki ingest
```

### Query what you know

```
wiki query what do I know about event sourcing?
wiki query compare FastAPI vs Express
wiki query how do I deploy Caddy with HTTPS?
```

Answers cite the specific wiki pages used. If there are gaps it tells you what to import.

### Maintenance

```
wiki lint              # find broken links, orphans, duplicates
wiki filter evolve     # tune relevance weights based on actual usage
```

---

## Recommended cadence

| When | Command |
|------|---------|
| Morning / after writing | `wiki scan` |
| Read something worth keeping | `wiki add <url>` then `wiki ingest` |
| Before starting a project | `wiki query <topic>` |
| Monthly | `wiki lint` + `wiki filter evolve` |

---

## File structure

```
neuron/
├── Makefile
├── README.md
├── LICENSE
├── CONTRIBUTING.md
├── .gitignore
├── SKILL.md                         # Router — dispatches all wiki commands
├── skills/
│   ├── bootstrap.md                 # One-time vault initialization
│   ├── scan.md                      # Daily vault scan → import → ingest
│   ├── add.md                       # Manual single-source import
│   ├── ingest.md                    # Filter + transform pending sources
│   ├── query.md                     # Synthesize answers with citations
│   ├── lint.md                      # Health checks
│   └── filter.md                    # Identity filter management
├── scripts/                         # Deterministic operations (saves tokens)
│   ├── _config.sh                   # Shared config loader + cross-platform helpers
│   ├── find-pending-sources.sh      # Grep for ingested: false
│   ├── find-vault-notes.sh          # Find recently modified vault notes
│   ├── wiki-stats.sh               # Page/source counts and avg relevance
│   ├── lint-checks.sh              # All structural lint checks
│   ├── check-duplicate.sh          # Detect already-imported sources
│   ├── update-source-meta.sh       # Update source frontmatter fields
│   └── doctor.sh                   # Setup validation
├── references/
│   └── page-standards.md            # Page templates for all 5 types
└── schema/
    ├── config.example.yaml          # Template → ~/.llm-wiki/config.yaml
    ├── filter-identity.example.md   # Template → ~/.llm-wiki/filter-identity.md
    └── query-log.example.md         # Template → ~/.llm-wiki/query-log.md
```

The Obsidian vault gets two top-level folders managed by this skill:

```
Your Obsidian vault/
├── LLM-Wiki/                        # Wiki pages (LLM-maintained)
│   ├── _index.md                    # Map of Content
│   ├── Entities/
│   ├── Concepts/
│   ├── Topics/
│   ├── Recipes/
│   └── Comparisons/
└── LLM-Wiki-Sources/                # Raw imported sources (immutable)
    └── {year}/
```

---

## Scripts vs LLM — what runs where

LLMs are non-deterministic. Deterministic operations are offloaded to shell scripts for predictability and to save tokens.

| Operation | Handled by | Why |
|-----------|-----------|-----|
| Find `ingested: false` sources | `find-pending-sources.sh` | Pure grep |
| Find modified vault notes | `find-vault-notes.sh` | Date math + word count |
| Check duplicate imports | `check-duplicate.sh` | Pure grep |
| Update source frontmatter | `update-source-meta.sh` | Deterministic sed |
| Lint: orphans, broken links, frontmatter, index drift, stale sources | `lint-checks.sh` | All file-system checks |
| Page/source counts, avg relevance | `wiki-stats.sh` | Arithmetic |
| Score content against identity dimensions | **LLM** | Needs comprehension |
| Write/update wiki page content | **LLM** | Creative synthesis |
| Synthesize query answers | **LLM** | Semantic reasoning |
| Detect duplicate/misclassified pages | **LLM** | Semantic similarity |
| Propose filter evolution | **LLM** | Pattern analysis |

---

## Page types

| Type | For | Example |
|------|-----|---------|
| Entity | Specific thing: tool, project, person, company | FastAPI, Base Network |
| Concept | Idea, pattern, principle | Event Sourcing, Gas Fee Optimization |
| Topic | Broad area collecting related pages | Crypto Trading, Photography |
| Recipe | How-to procedure (code or cooking) | Deploy Caddy, Miso Ramen |
| Comparison | Side-by-side with explicit axes | AVIF vs WebP, FastAPI vs Express |

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

The filter at `~/.llm-wiki/filter-identity.md` defines scoring dimensions and weights. Each source is scored 0-1 against each dimension; the weighted sum is compared against a minimum threshold (default: 0.4). Sources below the threshold are marked ingested but don't get wiki pages — they stay in `LLM-Wiki-Sources/` for reference without cluttering the wiki.

Run `wiki filter evolve` periodically to tune weights based on what you actually query and link to. All filter changes require your approval and apply to future ingests only — existing pages are never retroactively removed.

---

## Troubleshooting

| Error | Fix |
|-------|-----|
| `Config not found at ~/.llm-wiki/config.yaml` | Run `make install` to create the config directory |
| `vault_path not set` | Edit `~/.llm-wiki/config.yaml` and set your vault path |
| `Vault not found at ...` | Check that the path in `config.yaml` is correct and the directory exists |
| `No user_vaults configured` | Add at least one vault path under `user_vaults:` in `config.yaml` |
| Scripts fail on Linux | Check `bash --version` is 4+; ensure scripts are executable (`chmod +x scripts/*.sh`) |

Run `scripts/doctor.sh` for a comprehensive setup check.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Credits

- [Andrej Karpathy](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — the LLM Wiki concept: a persistent, LLM-maintained knowledge base that compounds over time
- [Baljanak](https://gist.github.com/baljanak/f233d3e321d353d34f2f6663369b3105) — identity-aware learning filter: scoring sources against personal relevance dimensions with evolving weights

---

## License

[MIT](LICENSE)
