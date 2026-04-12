---
name: neuron-bootstrap
description: >
  Initialize the LLM Wiki structure in the Obsidian vault and draft the
  identity filter. Run this once when setting up the wiki for the first time.
  Triggers on: neuron bootstrap, wiki init, wiki setup.
---

# Wiki Bootstrap

Initialize the LLM Wiki folder structure in the Obsidian vault and draft an initial identity filter.

## Pre-flight Checks

1. Check if `CONFIG_DIR` (`~/.llm-wiki`) exists.
   - If not, create it: `mkdir -p ~/.llm-wiki`
   - If `CONFIG_DIR/config.yaml` doesn't exist, copy from `SKILL_DIR/schema/config.example.yaml` and prompt the user to set their vault path before continuing.
2. Read `CONFIG_DIR/config.yaml` to get the vault path.
3. Check if `VAULT/LLM-Wiki/` already exists.
   - If it does, warn the user: "LLM Wiki is already initialized. Re-running will not overwrite existing content." Only create missing folders/files.
   - If it doesn't, proceed with full initialization.

## Step 1: Create Vault Folders

Create the following directories in the Obsidian vault:

```
VAULT/LLM-Wiki/
VAULT/LLM-Wiki/Entities/
VAULT/LLM-Wiki/Concepts/
VAULT/LLM-Wiki/Topics/
VAULT/LLM-Wiki/Recipes/
VAULT/LLM-Wiki/Comparisons/
VAULT/LLM-Wiki-Sources/
VAULT/LLM-Wiki-Sources/{current_year}/
```

Use `mkdir -p` with properly quoted paths (vault paths may contain spaces).

## Step 2: Create _index.md (Map of Content)

Write `VAULT/LLM-Wiki/_index.md`:

```markdown
---
title: "LLM Wiki — Map of Content"
type: index
created: {today}
updated: {today}
tags:
  - llm-wiki/index
aliases:
  - Wiki Index
  - LLM Wiki
---

# LLM Wiki

Personal knowledge base maintained by LLM. Import sources, filter by relevance, and build compounding knowledge.

## Entities
*Specific things: tools, projects, people, companies, protocols.*

<!-- ENTITIES_START -->
*No entities yet. Run `neuron add` then `neuron ingest` to populate.*
<!-- ENTITIES_END -->

## Concepts
*Ideas, patterns, principles, frameworks.*

<!-- CONCEPTS_START -->
*No concepts yet.*
<!-- CONCEPTS_END -->

## Topics
*Broad thematic areas collecting related pages.*

<!-- TOPICS_START -->
*No topics yet.*
<!-- TOPICS_END -->

## Recipes
*How-to procedures for code and life.*

<!-- RECIPES_START -->
*No recipes yet.*
<!-- RECIPES_END -->

## Comparisons
*Side-by-side analyses with explicit comparison axes.*

<!-- COMPARISONS_START -->
*No comparisons yet.*
<!-- COMPARISONS_END -->

---

*Last updated: {today}*
```

Replace `{today}` with the current date in YYYY-MM-DD format.

## Step 3: Draft Identity Filter

If `CONFIG_DIR/filter-identity.md` does not exist:

1. Read the existing Obsidian vault folder names (use `ls` on the vault root) to understand the user's interests.
2. Read `~/.claude/CLAUDE.md` or `~/.config/CLAUDE.md` if present, for context about the user's projects and domains.
3. Write `CONFIG_DIR/filter-identity.md` using the template from `SKILL_DIR/schema/filter-identity.example.md` as a base, but personalized to what you found.

If it already exists, skip this step.

## Step 4: Create Query Log

If `CONFIG_DIR/query-log.md` does not exist, copy `SKILL_DIR/schema/query-log.example.md` to `CONFIG_DIR/query-log.md`.

## Step 5: Confirm

Report to the user:
- Folders created in the vault
- Path to `_index.md`
- Whether identity filter was drafted or already existed
- Config location: `~/.llm-wiki/`
- Remind them to run `neuron add <source>` to start adding knowledge
