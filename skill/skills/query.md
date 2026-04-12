---
name: neuron-query
description: >
  Synthesize answers from the LLM Wiki knowledge base. Reads relevant wiki
  pages, constructs an answer with inline citations, and logs the query for
  filter evolution. Triggers on: neuron query, neuron q.
---

# Wiki Query

Answer questions by synthesizing information from wiki pages. Every claim in the answer must cite a wiki page or source.

## Process

### Step 1: Parse the Question

Extract the core question from the user's input. Examples:
- `neuron query what is event sourcing?`
- `neuron q compare FastAPI vs Express`
- `neuron query how do I deploy Caddy?`

### Step 2: Find Relevant Pages

1. Read `WIKI/_index.md` to get the full page listing.
2. Based on the question, identify candidate pages by:
   - Matching keywords in page titles and descriptions from the index.
   - Following `related` links from initially matched pages.
3. Read the candidate wiki pages (aim for the minimal set needed to answer).

If no relevant pages are found, skip to Step 5 (Knowledge Gaps).

### Step 3: Synthesize Answer

Construct an answer that:
- **Directly addresses the question** — lead with the answer, not background.
- **Cites wiki pages inline** — use `[[LLM-Wiki/Type/Page Name]]` for wiki pages, and `[[LLM-Wiki-Sources/YYYY/YYYY-MM-DD-slug|Name]]` for direct source references.
- **Cross-references related pages** — mention related wiki pages the user might want to explore.
- **Is concise** — this is a neuron query, not an essay. A few paragraphs max.

Format the response as markdown (Obsidian-compatible).

### Step 4: Log the Query

Append to `CONFIG_DIR/query-log.md`:

```
| {today} | {question} | {comma-separated page names used} | {gaps if any} |
```

This log feeds the filter evolution process — it shows what the user actually asks about, which helps tune relevance scoring.

### Step 5: Knowledge Gaps

If the question cannot be fully answered from existing wiki pages:

1. State what IS known from the wiki.
2. Identify what's missing: "The wiki doesn't have information about X."
3. Suggest imports: "To fill this gap, consider: `neuron add <suggested URL or topic>`"

If the wiki has NO relevant pages at all:
- "No wiki pages match this query. The wiki may not have content on this topic yet."
- Suggest: "Try `neuron add` with relevant sources, then `neuron ingest` to populate the wiki."

### Step 6: Page Creation (Optional)

If the query synthesis produced a valuable new insight that connects multiple wiki pages in a novel way:
- Ask the user: "This synthesis produced a useful cross-cutting view. Create a new Topic or Concept page for it?"
- Only create if the user agrees.
- The new page's `sources` should reference the wiki pages that contributed (not raw sources directly, unless the synthesis drew from them).

## Query Types

Handle these patterns:

| Pattern | Behavior |
|---------|----------|
| `neuron q what is X?` | Find entity or concept page, summarize with citations |
| `neuron q compare A vs B` | Find comparison page or synthesize from entity pages |
| `neuron q how do I X?` | Find recipe page or synthesize from relevant pages |
| `neuron q what do I know about X?` | List all pages related to X with brief summaries |
| `neuron q recent` | Show pages created/updated in the last 30 days |

## Important

- **Never hallucinate wiki content.** If a page doesn't exist, say so. Don't make up facts and attribute them to non-existent pages.
- **Cite specifically.** Don't say "according to the wiki" — say "according to [[LLM-Wiki/Concepts/Event Sourcing]]".
- **Stay within the wiki.** The query skill answers from wiki pages only, not from general knowledge. If the user wants general knowledge, they should ask outside the wiki context.
