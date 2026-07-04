# CONTEXT.md Format

## Structure

```md
# {Context Name}

{1-2 sentences: what this context is and why it exists.}

## Language

**Order**:
{1-2 sentence definition of the term.}
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request
```

## Rules

- **Be opinionated.** When multiple words exist for one concept, pick the best one and list the others under `_Avoid_`.
- **Keep definitions tight.** 1-2 sentences max. Define what it IS, not what it does.
- **Only include terms specific to this project's context.** General programming concepts (timeouts, error types, utility patterns) don't belong even if the project uses them heavily. Before adding a term, ask: is this unique to this context, or a general programming concept? Only the former belongs.
- **Group terms under subheadings** when natural clusters emerge. A flat list is fine for a single cohesive area — don't force groupings.

## Single vs multi-context repos

- **Single context (most repos):** one `CONTEXT.md` at the repo root.
- **Multiple contexts:** a `CONTEXT-MAP.md` at the repo root lists the contexts, where they live, and how they relate:

```md
# Context Map

## Contexts

- [Ordering](./src/ordering/CONTEXT.md) — receives and tracks customer orders
- [Billing](./src/billing/CONTEXT.md) — generates invoices and processes payments

## Relationships

- **Ordering → Billing**: Ordering emits `OrderPlaced` events; Billing consumes them to generate invoices
- **Ordering ↔ Billing**: shared types for `CustomerId` and `Money`
```

To infer which structure applies:

1. If `CONTEXT-MAP.md` exists, read it to find the contexts.
2. If only a root `CONTEXT.md` exists, it is a single-context repo.
3. If neither exists, create a root `CONTEXT.md` lazily when the first term is resolved.

When multiple contexts exist, infer which one the current topic relates to. If unclear, ask the user.
