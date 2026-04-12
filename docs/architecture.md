# Architecture

## Design principle

Neuron splits work into two layers:

- **Scripts** (`scripts/*.sh`) handle deterministic operations — file finding, metadata updates, lint checks. These are predictable, fast, and save LLM tokens.
- **Skills** (`skills/*.md`) handle semantic operations — scoring relevance, synthesizing pages, answering queries. These require comprehension and judgment.

`SKILL.md` is the router that dispatches user commands to the appropriate sub-skill.

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
├── docs/                            # Documentation
└── schema/
    ├── config.example.yaml          # Template → ~/.llm-wiki/config.yaml
    ├── filter-identity.example.md   # Template → ~/.llm-wiki/filter-identity.md
    └── query-log.example.md         # Template → ~/.llm-wiki/query-log.md
```

---

## Vault structure

The Obsidian vault gets two top-level folders managed by Neuron:

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

Folder names are configurable via `wiki_folder` and `sources_folder` in `config.yaml`.

---

## Scripts vs LLM

| Operation | Handled by | Why |
|-----------|-----------|-----|
| Find `ingested: false` sources | `find-pending-sources.sh` | Pure grep |
| Find modified vault notes | `find-vault-notes.sh` | Date math + word count |
| Check duplicate imports | `check-duplicate.sh` | Fixed-string grep |
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

Page templates and frontmatter specs are defined in [`references/page-standards.md`](../references/page-standards.md).

---

## Cross-platform support

All scripts source `_config.sh` which provides portable helpers:

| Helper | macOS | Linux |
|--------|-------|-------|
| `SED_INPLACE` | `sed -i ''` | `sed -i` |
| `portable_date_ago N d\|h` | `date -v-Nd` | `date -d 'N days ago'` |
| `portable_stat_mtime file` | `stat -f '%Sm'` | `stat -c '%y'` |
| `portable_date_days_ago N` | `date -v-Nd` | `date -d 'N days ago'` |
