# Commands

## Reference

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
