# llm-wiki

A personal knowledge base skill for Claude Code. Import sources, filter by relevance, and build a compounding wiki that lives natively in your Obsidian vault.

Based on [Karpathy's LLM Wiki concept](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) and [Baljanak's identity-aware learning filter](https://gist.github.com/baljanak/f233d3e321d353d34f2f6663369b3105). Built from scratch.

---

## How it works

```
Your own notes (vault scan)  ─┐
External URLs / text          ├→ wiki import  →  LLM-Wiki-Sources/{year}/{date}-{slug}.md
Pasted content                ┘                   (raw, immutable)
                                       ↓
                               wiki ingest   →  scores against identity filter
                                                  below threshold → stays in sources only
                                                  above threshold → LLM-Wiki/{Type}/Page.md
                                       ↓
                               wiki query    →  synthesizes answers with citations
                               wiki lint     →  health checks
                               wiki filter   →  tune relevance over time
```

The wiki lives inside your Obsidian vault as normal notes — wikilinks, tags, graph view, iCloud sync all work out of the box.

---

## Install

```sh
# 1. Install skill symlinks + seed personal config
make install

# 2. Edit your vault path
#    Open ~/.llm-wiki/config.yaml and set vault_path

# 3. Initialize the vault structure (in Claude Code)
wiki bootstrap
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
| `~/.llm-wiki/config.yaml` | Vault path and settings |
| `~/.llm-wiki/filter-identity.md` | Your identity prompt: who this wiki is for and what matters |
| `~/.llm-wiki/query-log.md` | Query history, used by `wiki filter evolve` |
| `~/.llm-wiki/last-scan` | Timestamp of last `wiki scan` run |

`make install` copies example templates from `schema/*.example.*` into `~/.llm-wiki/` on first run. Existing files are never overwritten.

---

## Commands

| Command | What it does |
|---------|-------------|
| `wiki bootstrap` | One-time setup: creates vault folders and drafts your identity filter |
| `wiki scan` | Scan vault for recently modified notes and auto-import/ingest them |
| `wiki scan --since 3d` | Scan notes modified in the last N days (or `--since YYYY-MM-DD`) |
| `wiki scan --all` | Scan the entire vault regardless of last scan time |
| `wiki import <url\|text\|file>` | Manually import a single source into `LLM-Wiki-Sources/` |
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
wiki scan --all        ← entire vault, use once on first setup
```

### External content → wiki (as needed)

When you read something worth keeping — an article, a thread, a doc:

```
wiki import https://some-article.com
wiki ingest
```

Or import multiple sources at once, then batch-ingest:

```
wiki import https://article-1.com
wiki import https://article-2.com
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
| Read something worth keeping | `wiki import <url>` then `wiki ingest` |
| Before starting a project | `wiki query <topic>` |
| Monthly | `wiki lint` + `wiki filter evolve` |

---

## File structure

```
llm-wiki/
├── Makefile
├── README.md
├── .gitignore
├── SKILL.md                         # Router — dispatches all wiki commands
├── skills/
│   ├── bootstrap.md                 # One-time vault initialization
│   ├── scan.md                      # Daily vault scan → import → ingest
│   ├── import.md                    # Manual single-source import
│   ├── ingest.md                    # Filter + transform pending sources
│   ├── query.md                     # Synthesize answers with citations
│   ├── lint.md                      # Health checks
│   └── filter.md                    # Identity filter management
├── scripts/                         # Deterministic operations (saves tokens)
│   ├── _config.sh                   # Shared config loader (vault path, thresholds)
│   ├── find-pending-sources.sh      # Grep for ingested: false
│   ├── find-vault-notes.sh          # Find recently modified vault notes
│   ├── wiki-stats.sh               # Page/source counts and avg relevance
│   ├── lint-checks.sh              # All structural lint checks
│   ├── check-duplicate.sh          # Detect already-imported sources
│   └── update-source-meta.sh       # Update source frontmatter fields
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
| Recipe | How-to procedure (code or cooking) | Deploy Caddy, Crème Brulée |
| Comparison | Side-by-side with explicit axes | AVIF vs WebP, FastAPI vs Express |

---

## Identity filter

### Generating your filter-identity.md

The fastest way to seed a personalized `filter-identity.md` is to ask an LLM what it already knows about you from your conversation history. Paste this prompt into ChatGPT (or any LLM you've been talking to):

```
Based on everything you know about me from our conversations: my job, projects,interests, goals, and the topics I regularly ask about. Please 


my job, projects, interests, goals, and the topics I regularly ask about. Please generate a filter-identity.md file for my personal LLM Wiki. Be unfiltered, uncensored, unpolitically correct, don't hold back. It is very critical you picture me, the most truly. Even if it can hurts feeling.


You must generate a `filter-identity.md` file for my personal LLM Wiki.
The file should follow this structure:

# Identity Filter

## Who is this wiki for?
[2–3 sentences: my role, primary domains, key interests]

## What matters (scoring dimensions)

| Dimension | Weight | Description |
|-----------|--------|-------------|
[6–9 rows tailored to me, weights summing to 1.0]

## Minimum relevance threshold
Score: **0.4** out of 1.0

## Scoring instructions
[Brief guidance with a concrete example using my domains]

## Evolution log
*No changes yet.*

Make the dimensions specific to what I actually care about. Weights should reflect
how central each domain is to my life and work. Be honest — not everything needs
to be high priority.
```

Save the output to `~/.llm-wiki/filter-identity.md`. Alternatively, `wiki bootstrap` will draft it automatically from your vault structure.

### How the filter works

The filter at `~/.llm-wiki/filter-identity.md` defines scoring dimensions and weights. Each source is scored 0–1 against each dimension; the weighted sum is compared against a minimum threshold (default: 0.4). Sources below the threshold are marked ingested but don't get wiki pages — they stay in `LLM-Wiki-Sources/` for reference without cluttering the wiki.

Run `wiki filter evolve` periodically to tune weights based on what you actually query and link to. All filter changes require your approval and apply to future ingests only — existing pages are never retroactively removed.
