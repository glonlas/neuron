# Page Standards — Wiki Page Templates

Every wiki page MUST have YAML frontmatter and follow the template for its type. All links use Obsidian `[[wikilink]]` syntax. All tags use the `llm-wiki/` prefix.

---

## Common Frontmatter (all page types)

```yaml
---
title: "Page Title"
type: entity | concept | topic | recipe | comparison
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources:
  - "[[LLM-Wiki-Sources/YYYY/YYYY-MM-DD-slug]]"
related:
  - "[[LLM-Wiki/Type/Related Page]]"
tags:
  - llm-wiki/{type}
  - llm-wiki/{domain}
relevance_score: 0.0-1.0
aliases:
  - alternate name
  - abbreviation
---
```

**Rules:**
- `sources` lists every raw source that contributed content to this page.
- `related` lists other wiki pages this page references or is closely connected to.
- `tags` always includes `llm-wiki/{type}`. Add domain tags like `llm-wiki/engineering`, `llm-wiki/crypto`, `llm-wiki/cooking`, etc.
- `relevance_score` is the filter's assessment at ingest time.
- `aliases` enables Obsidian quick-switcher and link autocomplete.

---

## Entity Page

For specific things: tools, projects, people, companies, protocols, runtimes.

```markdown
## What it is
One-paragraph definition. What is this thing?

## Role & Context
Where does it fit? What system or domain does it belong to? Why does it exist?

## Key Features / Interfaces
- Bullet list of notable capabilities, APIs, or characteristics.

## How it works
Operational overview. What does it do at runtime or in practice?

## Failure Modes & Gotchas
Known issues, edge cases, common mistakes.

## Sources
- [[LLM-Wiki-Sources/YYYY/YYYY-MM-DD-slug|Display Name]]
```

---

## Concept Page

For ideas, patterns, principles, frameworks, methodologies.

```markdown
## What it governs
What domain or problem does this concept address?

## Core Structure
The key components or rules of this concept. How it works in the abstract.

## In Practice
How this concept manifests in real systems or workflows. Concrete examples.

## Failure Modes
What happens when this concept is applied incorrectly or ignored?

## Why it matters
The practical value. Why should someone care about this concept?

## Sources
- [[LLM-Wiki-Sources/YYYY/YYYY-MM-DD-slug|Display Name]]
```

---

## Topic Page

For broad areas that collect related entities and concepts. Provides a thematic overview.

```markdown
## Scope
What this topic covers and what it explicitly does NOT cover.

## Key Entities
Links to entity pages within this topic:
- [[LLM-Wiki/Entities/Entity Name]] — brief note on relevance

## Key Concepts
Links to concept pages within this topic:
- [[LLM-Wiki/Concepts/Concept Name]] — brief note on relevance

## Main Patterns
Recurring themes, workflows, or approaches observed across this topic.

## Current State & Open Questions
What's settled, what's in flux, what gaps remain in our understanding.

## Sources
- [[LLM-Wiki-Sources/YYYY/YYYY-MM-DD-slug|Display Name]]
```

---

## Recipe Page

For how-to procedures — both technical (deploy, configure, build) and non-technical (cooking, photography techniques).

```markdown
## Goal
What this recipe achieves. One sentence.

## Prerequisites
What you need before starting (tools, ingredients, access, dependencies).

## Steps
1. First step with specific details.
2. Second step.
3. Continue with numbered steps.

## Verification
How to confirm the recipe worked. Expected output or result.

## Variations & Notes
Alternative approaches, substitutions, tips from experience.

## Sources
- [[LLM-Wiki-Sources/YYYY/YYYY-MM-DD-slug|Display Name]]
```

---

## Comparison Page

For side-by-side analysis. MUST define explicit comparison axes.

```markdown
## Subjects
What is being compared: [[Entity A]] vs [[Entity B]] (link to entity pages if they exist).

## Comparison Axes
Define the dimensions being compared. Every comparison MUST have explicit axes.

| Axis | Subject A | Subject B |
|------|-----------|-----------|
| Performance | ... | ... |
| Ease of use | ... | ... |
| Cost | ... | ... |

## Key Differences
The most important distinctions, explained in prose.

## When to Choose Each
Decision guidance: under what circumstances is each subject the better choice?

## Sources
- [[LLM-Wiki-Sources/YYYY/YYYY-MM-DD-slug|Display Name]]
```

---

## Inline Citation Format

When referencing a source within page content, use:
```
According to [[LLM-Wiki-Sources/YYYY/YYYY-MM-DD-slug|Author/Title YYYY]], ...
```

This creates a clickable link in Obsidian that displays the friendly name but links to the source file.

---

## Naming Conventions

- **File names**: Use Title Case with spaces (Obsidian handles this well). Example: `Event Sourcing.md`
- **Folder structure**: `LLM-Wiki/{Type}/{Page Name}.md`
- **Source files**: `LLM-Wiki-Sources/{year}/{YYYY-MM-DD}-{slug}.md` where slug is lowercase-kebab-case.
- **No nested sub-folders** within type folders. Keep it flat per type.
