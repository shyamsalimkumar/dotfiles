---
name: research
description: Research a topic across one or more codebases by spawning parallel subagents to explore different aspects, then synthesize findings into a structured doc. Use when asked to "research X", "document how X works", "map out X", "explain X across the codebase", or "how does X work".
---

Research a codebase topic: decompose it into parallel subagent queries, then synthesize the results into one document.

## Process

### 1. Clarify scope (if needed)

If the research question is ambiguous, ask exactly one focused question before proceeding — e.g. which repo, which layer, or what output format is wanted. Never ask more than one.

### 2. Decompose into sub-questions

Break the topic into 3–6 independent sub-questions that can be investigated in parallel. Each must be narrow enough that a single Explore subagent can answer it by reading files and grepping — not open-ended analysis.

Example: "How does auth work?" → where tokens are issued / how middleware validates / how refresh works / where the session model lives. Other shapes: "How is data ingested?" → entry points / pipeline / persistence / error handling; "What does billing own?" → data models / external calls / events / test coverage.

### 3. Spawn subagents in parallel

Launch ALL subagents in a single message by making parallel Task tool calls with subagent_type `Explore` — never fan out sequentially. Give each subagent:
- A precise question
- The relevant starting path(s) to search
- Instruction to return findings as bullet points, not prose — key facts, file paths with line numbers, and any surprises

Example prompt per subagent:
> "Find where JWT tokens are validated in this repo. Search from `src/`. Return: the file(s) and line numbers where validation happens, what library is used, and whether there's any bypass path. Bullet points only, under 200 words."

### 4. Synthesize

Read all subagent results and write a single structured markdown document. Do not paste raw subagent output — synthesize it. Structure:

```
# Research: <topic>

## Summary
Two or three sentences: what you found and the most important insight.

## Codemap
A structured index of every significant entry point, type, or decision point found.
Group by concept, not by file. Dense, no prose — every row must be a real location you found. Format:

| Concept | File | Lines | Notes |
|---|---|---|---|
| Token validation middleware | src/auth/middleware.ts | 42–67 | Skipped for public routes |
| Session model | src/models/session.go | 1–80 | Redis-backed |

## <Section per major aspect>
Findings, with [file:line](path#Lline) links for every claim that has a source.

## Open questions
Things that were unclear or not found — so the reader knows the limits of this doc.
```

### 5. Write or display

- If the user asked for a file: write it to the path they specified, or `docs/research/<slug>.md` by default.
- Otherwise: output the document directly in the conversation.

## Rules

- **Cite sources.** Every factual claim about the code gets a `[file:line](path#Lline)` link. Unsourced claims are forbidden.
- **No speculation.** If a subagent couldn't find something, say so in Open questions — never fill the gap with guesses.
- **Parallel first.** All subagents go out in one message.
- **One doc.** Do not hand back raw subagent dumps. The value is synthesis.
- **Scope to what was asked.** Don't expand into adjacent topics unless directly relevant.
