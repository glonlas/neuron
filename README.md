# Neuron

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg)]()
[![Claude Code](https://img.shields.io/badge/Claude%20Code-skill-blueviolet.svg)]()

A [Claude Code](https://claude.ai/code) skill that turns your reading into a personal, compounding knowledge wiki inside [Obsidian](https://obsidian.md/). Import anything — URLs, notes, pasted text — and Neuron filters it through your identity profile, keeps only what matters, and builds structured wiki pages with full source traceability.

Supports **multiple Obsidian vaults** as sources (e.g. a personal vault and a work vault) — Neuron scans all of them and writes everything into one unified wiki.

```
Sources (URLs, notes, text)  →  wiki add   →  raw sources (immutable)
                                    ↓
                             wiki ingest  →  score against identity filter
                                              below threshold → archived
                                              above threshold → wiki page
                                    ↓
                             wiki query   →  answers with citations
                             wiki lint    →  health checks
                             wiki filter  →  evolve relevance over time
```

Inspired by [Karpathy's LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) and [Baljanak's learning filter](https://gist.github.com/baljanak/f233d3e321d353d34f2f6663369b3105). Built from scratch.

---

## Getting started

**Prerequisites:** [Claude Code](https://claude.ai/code), Bash 4+

```sh
git clone https://github.com/glonlas/neuron.git && cd neuron
make install                        # symlinks + seed ~/.llm-wiki/ config
# Edit ~/.llm-wiki/config.yaml     # set vault_path
wiki bootstrap                      # run in Claude Code to init vault
```

Validate: `scripts/doctor.sh` | Uninstall: `make uninstall`

---

## Example

```
# In Claude Code
wiki add https://www.reddit.com/r/LocalLLaMA/comments/1s49lvh/gguf_llamacpp_vs_mlx_round_2_your_feedback_tested/
wiki ingest
```

Neuron fetches the thread, scores it against your identity filter, and — if it clears your relevance threshold — creates a structured wiki page (e.g. `LLM-Wiki/Comparisons/GGUF llama.cpp vs MLX.md`) with inline citations back to the source.

---

## Automation

Set up cron jobs so the wiki stays fresh without manual effort:

```sh
# Daily: ingest any pending sources at 8am
0 8 * * * /path/to/claude -p "wiki ingest" >> ~/.llm-wiki/cron.log 2>&1

# Weekly: lint + evolve filter every Monday at 9am
0 9 * * 1 /path/to/claude -p "wiki lint" >> ~/.llm-wiki/cron.log 2>&1
0 9 * * 1 /path/to/claude -p "wiki filter evolve" >> ~/.llm-wiki/cron.log 2>&1
```

Add to your crontab with `crontab -e`. Use the full path to `claude` (run `which claude` to find it — typically `/opt/homebrew/bin/claude` on macOS). Pair with `wiki scan` in your morning terminal session to pull overnight note changes.

---

## Quick reference

| Command | What it does |
|---------|-------------|
| `wiki scan` | Pull recently modified vault notes into the wiki |
| `wiki add <url\|text>` | Import a single source |
| `wiki ingest` | Score pending sources, create wiki pages |
| `wiki query <question>` | Answer from wiki with citations |
| `wiki lint` | Health check |
| `wiki filter evolve` | Tune relevance weights from usage patterns |

---

## Documentation

| Doc | Contents |
|-----|----------|
| [Commands](docs/commands.md) | Full command reference, daily usage patterns, recommended cadence |
| [Configuration](docs/configuration.md) | config.yaml, identity filter setup, scoring dimensions |
| [Architecture](docs/architecture.md) | File structure, scripts vs LLM split, page types, cross-platform support |
| [Troubleshooting](docs/troubleshooting.md) | Common errors and doctor.sh |
| [Contributing](CONTRIBUTING.md) | How to add skills, scripts, and submit PRs |

---

## Credits

- [Andrej Karpathy](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — the LLM Wiki concept
- [Baljanak](https://gist.github.com/baljanak/f233d3e321d353d34f2f6663369b3105) — identity-aware learning filter

## License

[MIT](LICENSE)
