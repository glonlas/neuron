# Identity Filter

## Who is this wiki for?

{2–3 sentences describing yourself: your role, primary domains, and key interests.
This is used by the ingest skill to decide what knowledge is worth a wiki page.
Be specific — the more precise the identity, the sharper the filtering.}

Example: "I'm a senior software engineer who builds full-stack systems across crypto, AI agents,
and infrastructure. I also track personal finance (SGD-anchored), practice photography, and cook."

## What matters (scoring dimensions)

Customize the dimensions and weights to match your interests.
Weights must sum to 1.0.

| Dimension | Weight | Description |
|-----------|--------|-------------|
| Engineering & Architecture | 0.25 | Software design, systems, DevOps, languages, frameworks |
| {Domain 2} | 0.20 | {Description} |
| {Domain 3} | 0.20 | {Description} |
| {Domain 4} | 0.10 | {Description} |
| {Domain 5} | 0.10 | {Description} |
| {Domain 6} | 0.05 | {Description} |
| {Domain 7} | 0.05 | {Description} |
| Curiosity Wildcard | 0.05 | Anything genuinely novel that doesn't fit above |

## Minimum relevance threshold

Score: **0.4** out of 1.0

Sources scoring below this threshold will be marked as ingested but will NOT get wiki pages.
They remain searchable in LLM-Wiki-Sources/ but don't clutter the curated wiki.

## Scoring instructions

For each source, compute a weighted sum across the dimensions above.
Rate each dimension 0.0–1.0 for how relevant the source is to that dimension,
then multiply by weight and sum.

- If a source is borderline (0.35–0.45) but contains a genuinely novel insight, round up.
- If a source scores well but is shallow or already covered by existing pages, skip it.
- Decision-relevant content (changes how you'd build or invest) gets a bonus.

## Evolution log

*No changes yet.*
