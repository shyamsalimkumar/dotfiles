---
name: improve-codebase-architecture
description: Find deepening opportunities in a codebase, informed by the domain language in CONTEXT.md and the decisions in docs/adr/. Use when the user wants to improve architecture, find refactoring opportunities, consolidate tightly-coupled modules, or make a codebase more testable and AI-navigable.
---
<!-- imported from: https://github.com/mattpocock/skills/blob/main/skills/engineering/improve-codebase-architecture/SKILL.md -->

# Improve Codebase Architecture

Surface architectural friction and propose **deepening opportunities** — refactors that turn shallow modules into deep ones. The aim is testability and AI-navigability.

## Glossary

Use these terms exactly in every suggestion. Do not drift into "component," "service," "API," or "boundary."

- **Module** — anything with an interface and an implementation (function, class, package, slice).
- **Interface** — everything a caller must know to use the module: types, invariants, error modes, ordering, config. Not just the type signature.
- **Implementation** — the code inside.
- **Depth** — leverage at the interface: a lot of behaviour behind a small interface. **Deep** = high leverage. **Shallow** = interface nearly as complex as the implementation.
- **Seam** — where an interface lives; a place behaviour can be altered without editing in place. (Use this, not "boundary.")
- **Adapter** — a concrete thing satisfying an interface at a seam.
- **Leverage** — what callers get from depth.
- **Locality** — what maintainers get from depth: change, bugs, knowledge concentrated in one place.

Key principles:

- **Deletion test**: imagine deleting the module. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it was earning its keep.
- **The interface is the test surface.**
- **One adapter = hypothetical seam. Two adapters = real seam.**

The project's domain language (`CONTEXT.md`) names good seams; ADRs (`docs/adr/`) record decisions this skill must not re-litigate.

## Process

### 1. Explore

First read the project's `CONTEXT.md` glossary and any ADRs in the area you're touching. If `CONTEXT.md` or `docs/adr/` don't exist, skip them and use the codebase's own naming in the report.

Then spawn an Explore subagent (Task/Agent tool, `subagent_type=Explore`) to walk the codebase; if no subagent tool is available, explore directly. Explore organically — no rigid heuristics — and note friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow** — interface nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, while the real bugs hide in how they're called (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts are untested, or hard to test through their current interface?

Apply the **deletion test** to anything you suspect is shallow: would deleting it concentrate complexity, or just move it? "Concentrates" is the signal you want.

### 2. Present candidates as an HTML report

Write a self-contained HTML file to the OS temp directory so nothing lands in the repo. Resolve the temp dir from `$TMPDIR`, falling back to `/tmp` (or `%TEMP%` on Windows). Write to `<tmpdir>/architecture-review-<timestamp>.html` so each run gets a fresh file. Open it for the user (`open <path>` on macOS, `xdg-open <path>` on Linux, `start <path>` on Windows) and tell them the absolute path.

Style with **Tailwind via CDN**. Draw diagrams with **Mermaid via CDN** where relationships are graph-shaped (call graphs, dependencies, sequences); use hand-built divs/SVG for more editorial visuals (mass diagrams, cross-sections, collapse animations). Be visual.

Render each candidate as a card with:

- **Files** — files/modules involved
- **Problem** — why the current architecture causes friction
- **Solution** — plain-English description of what would change
- **Benefits** — in terms of locality and leverage, and how tests would improve
- **Before / After diagram** — side-by-side, custom-drawn, showing the shallowness and the deepening
- **Recommendation strength** — badge: `Strong`, `Worth exploring`, or `Speculative`

End the report with a **Top recommendation** section: which candidate to tackle first and why.

**Use `CONTEXT.md` vocabulary for the domain and the Glossary above for the architecture.** If `CONTEXT.md` defines "Order," say "the Order intake module" — not "the FooBarHandler," and not "the Order service."

**ADR conflicts**: if a candidate contradicts an existing ADR, surface it only when the friction is real enough to warrant revisiting the ADR, and mark it clearly on the card with a warning callout (e.g. _"contradicts ADR-0007 — but worth reopening because…"_). Do not list every theoretical refactor an ADR forbids.

Do NOT propose interfaces yet. After the file is written, ask the user: "Which of these would you like to explore?"

### 3. Grilling loop

Once the user picks a candidate, interview them through the design tree: constraints, dependencies, the shape of the deepened module, what sits behind the seam, what tests survive.

Apply side effects inline as decisions crystallize:

- **Deepened module named after a concept not in `CONTEXT.md`?** Add the term to `CONTEXT.md` immediately, following [CONTEXT-FORMAT.md](../grill-with-docs/CONTEXT-FORMAT.md); create the file lazily if it doesn't exist. `CONTEXT.md` is a glossary only — no implementation details.
- **A fuzzy term got sharpened during the conversation?** Update `CONTEXT.md` right there.
- **User rejects the candidate with a load-bearing reason?** Offer an ADR (in `docs/adr/`), framed as: _"Want me to record this as an ADR so future architecture reviews don't re-suggest it?"_ Offer only when a future explorer would need the reason to avoid re-suggesting the same thing — skip ephemeral reasons ("not worth it right now") and self-evident ones. Follow the format and naming in [ADR-FORMAT.md](../grill-with-docs/ADR-FORMAT.md).
- **User wants to explore alternative interfaces for the deepened module?** Sketch 2–3 alternative interfaces and compare them on depth: how much behaviour each hides behind how small an interface.
