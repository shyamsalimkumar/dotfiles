# UI Prototype

Generate several radically different UI variants on a single route, switchable via a `?variant=` URL search param and a floating bottom bar. The user flips between them in the browser, picks one (or steals bits from each), and the rest gets deleted. Right shape for: "what should this page look like?", "show me options for this dashboard", "try a different layout". If the question is about logic or state, wrong branch — use [LOGIC.md](LOGIC.md).

## Choose where the variants live — strongly prefer A

Variants are easiest to judge butting up against the real app — real header, sidebar, data, density. On an empty route every variant looks fine.

**Sub-shape A — existing page (default).** Render variants on the existing route, gated by `?variant=`. Keep all existing data fetching, params, and auth — only the rendered subtree swaps. Also use A when the thing has no page yet but naturally lives inside one (a new dashboard section, a new settings card, a new step in an existing flow): mount the variants inside that host page.

**Sub-shape B — new page (last resort).** Only when there is genuinely no existing page to host it (an entirely new top-level surface, a flow that can't be embedded). Before choosing B, double-check there really is no host page — an empty route hides design problems a populated one would expose. Create a throwaway route following the project's existing routing convention; make the path or filename obviously a prototype (include the word `prototype`). Same `?variant=` pattern.

The floating bottom bar is identical in both sub-shapes.

## Steps

### 1. State the plan and pick N

Default to **3 variants**; hard cap at 5 — more stops being radically different and becomes noise. Write the plan in one line, in the prototype's location or a top-of-file comment, e.g.:

> "Three variants of the settings page, switchable via `?variant=`, on the existing `/settings` route."

### 2. Generate radically different variants

Each variant must:

- Serve the page's purpose using the data the page actually has access to.
- Use the project's component library / styling system (TailwindCSS, shadcn, MUI, plain CSS — whatever exists).
- Export a clearly named component: `VariantA`, `VariantB`, `VariantC`. Optionally also export a display-name constant (e.g. `export const VariantBName = 'Sidebar layout'`) for the switcher label.

Variants must be **structurally different** — different layout, information hierarchy, and primary affordance, not just different colours. If two drafts come out similar, redo one with an explicit constraint like "do not use a card grid".

### 3. Wire them together

One switcher component on the route:

```tsx
// pseudo-code — adapt to the project's framework
const variant = searchParams.get('variant') ?? 'A';
return (
  <>
    {variant === 'A' && <VariantA {...data} />}
    {variant === 'B' && <VariantB {...data} />}
    {variant === 'C' && <VariantC {...data} />}
    <PrototypeSwitcher variants={['A','B','C']} current={variant} />
  </>
);
```

Sub-shape A: keep existing data fetching above the switcher; only the rendered subtree changes per variant. Sub-shape B: the throwaway route (created per the sub-shape B rules above) mounts the same switcher.

### 4. Build the floating switcher

A fixed-position bar at the bottom-centre with three pieces: **left arrow** (previous variant, wraps around), **variant label** (current key plus the variant's display-name constant from step 2 if it exports one, e.g. `B — Sidebar layout`), **right arrow** (next, wraps around). Requirements:

- Arrows update the URL search param via the framework's router (`router.replace` on Next, `navigate` on React Router) so variants are shareable and reload-stable.
- `←` / `→` keys also cycle — but not while an `<input>`, `<textarea>`, or `[contenteditable]` is focused.
- Visually distinct from the page (high-contrast pill, subtle shadow) so it's obviously not part of the design being evaluated.
- Hidden in production builds — gate on `process.env.NODE_ENV !== 'production'` or equivalent, so a stray merge can't ship the bar to users.
- Build it as one shared component, placed wherever shared UI lives in the project, so both sub-shapes reuse it.

### 5. Hand it over

Give the user the URL and the `?variant=` keys. The interesting feedback is usually "I want the header from B with the sidebar from C" — that combination is the actual design they want.

### 6. Capture the answer and clean up

Record which variant won and why (commit message, ADR, issue, or a `NOTES.md` next to the prototype if the user hasn't responded yet). Then:

- **Sub-shape A** — delete the losing variants and the switcher; fold the winner into the existing page.
- **Sub-shape B** — promote the winner to a real route; delete the throwaway route and the switcher.

Never leave variant components or the switcher in the repo — they rot fast and confuse the next reader.

## Anti-patterns

- **Variants that differ only in colour or copy.** That's a tweak. Real variants disagree about structure.
- **Sharing too much code between variants.** A shared `<Header>` is fine; a shared `<Layout>` defeats the point — each variant must be free to throw out the layout.
- **Wiring variants to real mutations.** Read-only is fine; if a variant must mutate, point it at a stub. The question is looks, not the backend.
- **Promoting prototype code directly to production.** It was written under prototype constraints (no tests, minimal error handling) — rewrite it properly when folding it in.
