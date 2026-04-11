# llm-wiki

A personal knowledge base skill for Claude Code. Import sources, filter by relevance, and build a compounding wiki that lives natively in your Obsidian vault.

Based on [Karpathy's LLM Wiki concept](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) and [Baljanak's identity-aware learning filter](https://gist.github.com/baljanak/f233d3e321d353d34f2f6663369b3105). Built from scratch.

---

## How it works

```
Source (URL / text / file)
  → wiki import   →  LLM-Wiki-Sources/{year}/{date}-{slug}.md  (raw, immutable)
  → wiki ingest   →  scores against identity filter
                      below threshold → stays in sources only
                      above threshold → LLM-Wiki/{Type}/Page.md (Obsidian-native)
  → wiki query    →  synthesizes answers with citations
  → wiki lint     →  health checks
  → wiki filter   →  tune relevance over time
```

The wiki lives inside your Obsidian vault as normal notes — wikilinks, tags, graph view, iCloud sync all work out of the box.

---

## Install

```sh
# 1. Install skill symlinks
make install

# 2. Seed personal config into ~/.llm-wiki/
make setup

# 3. Edit your vault path
#    Open ~/.llm-wiki/config.yaml and set vault_path

# 4. Initialize the vault structure
#    (In Claude Code) wiki bootstrap
```

To remove the symlinks:

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

`make setup` copies the example templates from `schema/*.example.*` into `~/.llm-wiki/` on first run. Existing files are never overwritten.

---

## Commands

| Command | What it does |
|---------|-------------|
| `wiki bootstrap` | One-time setup: creates vault folders and drafts your identity filter |
| `wiki import <url\|text\|file>` | Saves a source to `LLM-Wiki-Sources/` for later ingestion |
| `wiki ingest` | Scores pending sources against your filter; creates wiki pages for qualifying ones |
| `wiki query <question>` | Synthesizes an answer from wiki pages with inline citations |
| `wiki lint` | Health check: orphan sources, broken links, duplicates, stale pages |
| `wiki filter show` | Display current identity filter and scoring dimensions |
| `wiki filter score <source>` | Manually score a source without ingesting it |
| `wiki filter evolve` | Analyze usage patterns and propose filter weight adjustments |

---

## File structure

```
llm-wiki/
├── Makefile
├── README.md
├── .gitignore
├── SKILL.md                         # Router skill — dispatches wiki commands
├── skills/
│   ├── bootstrap.md                 # Initialize vault structure
│   ├── import.md                    # Acquire sources
│   ├── ingest.md                    # Filter + transform to wiki pages
│   ├── query.md                     # Synthesize answers
│   ├── lint.md                      # Health checks
│   └── filter.md                    # Identity filter management
├── references/
│   └── page-standards.md            # Page templates for all 5 types
└── schema/
    ├── config.example.yaml          # Template — copy to ~/.llm-wiki/config.yaml
    ├── filter-identity.example.md   # Template — copy to ~/.llm-wiki/filter-identity.md
    └── query-log.example.md         # Template — copy to ~/.llm-wiki/query-log.md
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
Based on everything you know about me from our conversations — my job, projects,
interests, goals, and the topics I regularly ask about — please generate a
filter-identity.md file for my personal LLM Wiki.

The file should follow this structure:

---
# Identity Filter

## Who is this wiki for?
[2–3 sentences describing who I am: my role, primary domains, key interests]

## What matters (scoring dimensions)

| Dimension | Weight | Description |
|-----------|--------|-------------|
[List 6–9 dimensions tailored to me, with weights summing to 1.0]

## Minimum relevance threshold
Score: **0.4** out of 1.0

## Scoring instructions
[Brief guidance on how to apply the scoring, with a concrete example using my domains]

## Evolution log
*No changes yet.*
---

Make the dimensions specific to what I actually care about. Weights should reflect
how central each domain is to my life and work. Be honest — not everything needs
to be high priority.
```

Save the output to `~/.llm-wiki/filter-identity.md`. You can also run `wiki bootstrap` and let Claude draft it automatically from your vault structure and CLAUDE.md if you have one.

### How the filter works

The filter at `~/.llm-wiki/filter-identity.md` defines scoring dimensions and weights. Each source is scored 0–1 against each dimension; the weighted sum is compared against a minimum threshold (default: 0.4). Sources below the threshold are marked ingested but don't get wiki pages — they stay in `LLM-Wiki-Sources/` for reference without cluttering the wiki.

Run `wiki filter evolve` periodically to tune weights based on what you actually query and link to. All filter changes require your approval and apply to future ingests only — existing pages are never retroactively removed.
