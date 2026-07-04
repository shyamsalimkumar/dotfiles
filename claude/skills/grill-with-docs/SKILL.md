---
name: grill-with-docs
description: Grilling session that challenges your plan against the existing domain model, sharpens terminology, and updates documentation (CONTEXT.md, ADRs) inline as decisions crystallise. Use when the user wants to stress-test a plan against their project's language and documented decisions, or says "grill with docs".
---
<!-- imported from: https://github.com/mattpocock/skills/blob/main/skills/engineering/grill-with-docs/SKILL.md -->

Interview the user relentlessly about every aspect of their plan until you reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one by one.

Questioning rules:

1. Ask one question at a time; wait for the user's answer before asking the next.
2. With every question, state your recommended answer.
3. If a question can be answered by exploring the codebase, explore the codebase instead of asking.

## Find existing docs first

While exploring the codebase, also locate existing domain documentation:

- Root `CONTEXT.md` — the project glossary. Most repos have a single context.
- Root `docs/adr/` — architecture decision records, e.g. `0001-event-sourced-orders.md`.
- Root `CONTEXT-MAP.md` — if present, the repo has multiple contexts. It points to where each context lives; each context directory has its own `CONTEXT.md` and `docs/adr/`, and the root `docs/adr/` holds system-wide decisions.

Create files lazily — only when you have something to write. If no `CONTEXT.md` exists, create one when the first term is resolved. If no `docs/adr/` exists, create it when the first ADR is needed.

## During the session

1. **Challenge against the glossary.** When the user uses a term that conflicts with `CONTEXT.md`, call it out immediately: "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"
2. **Sharpen fuzzy language.** When the user uses a vague or overloaded term, propose a precise canonical term: "You're saying 'account' — do you mean the Customer or the User? Those are different things."
3. **Discuss concrete scenarios.** When domain relationships are being discussed, invent specific scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.
4. **Cross-reference with code.** When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"
5. **Update CONTEXT.md inline.** The moment a term is resolved, write it to `CONTEXT.md` — do not batch updates. Before the first write, read [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md) and follow it. `CONTEXT.md` is a glossary and nothing else: no implementation details, no spec content, no scratch notes, no implementation decisions.
6. **Offer ADRs sparingly.** Offer to create an ADR only when ALL three are true:
   1. **Hard to reverse** — changing the decision later has meaningful cost
   2. **Surprising without context** — a future reader would wonder "why did they do it this way?"
   3. **The result of a real trade-off** — genuine alternatives existed and one was picked for specific reasons

   If any of the three is missing, skip the ADR. Before writing one, read [ADR-FORMAT.md](./ADR-FORMAT.md) and follow it.
