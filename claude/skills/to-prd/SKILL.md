---
name: to-prd
description: Turn the current conversation context into a PRD and publish it to the project issue tracker. Use when the user says "to-prd", "write a PRD", "turn this into a PRD", or wants a PRD created from the current context.
---
<!-- imported from: https://github.com/mattpocock/skills/blob/main/skills/engineering/to-prd/SKILL.md -->

Synthesize the current conversation and codebase understanding into a PRD. Do NOT interview the user about the feature — use what you already know.

## Process

1. Explore the repo to understand the current state of the codebase, if you haven't already. Read these files if they exist — they are the authoritative config for this skill:
   - `CONTEXT.md` — domain vocabulary and architecture; use this language throughout the PRD
   - `docs/adr/` — past architectural decisions; respect them
   - `docs/agents/issue-tracker.md` — where and how to write issues
   - `docs/agents/triage-labels.md` — how to express triage state
   - `docs/agents/domain.md` — domain doc layout (single vs multi-context)

   If any of these are missing, do NOT fall back to `CLAUDE.md` or proceed without them. Run the "Inline setup" section below first, then continue.

2. Sketch the major modules to build or modify. Actively look for opportunities to extract deep modules that can be tested in isolation — a deep module encapsulates a lot of functionality behind a simple, testable interface that rarely changes. Then ask the user: (a) do these modules match their expectations? (b) which modules should get tests? Wait for the user's answers before proceeding to step 3; incorporate them into the Implementation Decisions and Testing Decisions sections.

3. Write the PRD using the template below and publish it to the project issue tracker. Apply the triage label that corresponds to the ready-for-agent state as defined in `docs/agents/triage-labels.md` (default: `ready-for-agent`) — no additional triage needed.

## Inline setup (only when config files are missing)

Explore the repo first, then walk the user through the three decisions **one at a time** — present a section, get an answer, then move to the next. Do not dump all three at once.

**Section A — Issue tracker.** Explain: this is where `to-prd` will write issues. Run `git remote -v`: if the remote is GitHub, propose GitHub as the default; if GitLab, propose GitLab; otherwise offer local markdown. Choices:

- **GitHub** — issues in GitHub Issues, created via `gh issue create`
- **GitLab** — issues in GitLab Issues, created via `glab issue create`
- **Local markdown** — issues as files inside the repo (no external CLI needed)
- **Other** — ask the user to describe the workflow in one paragraph

If local markdown, ask three follow-up questions (one at a time):
1. What path should issue files live under? (e.g. `plans/<feature>/issues/`)
2. What file naming convention? (e.g. numbered `001-slug.md`, flat `slug.md`)
3. How should triage state be tracked? (frontmatter `status:` field, subfolders, or filename prefix like `[ready] 001-slug.md`)

**Section B — Triage label vocabulary.** Explain: these five states drive the triage skill's state machine. For GitHub/GitLab they map to label strings; for local markdown they map to the encoding chosen in Section A. Defaults:

- `needs-triage` — maintainer needs to evaluate
- `needs-info` — waiting on reporter
- `ready-for-agent` — fully specified, AFK-ready
- `ready-for-human` — needs human implementation
- `wontfix` — will not be actioned

Ask: override any of these strings/prefixes, or keep the defaults?

**Section C — Domain docs.** Explain: some skills read `CONTEXT.md` for domain vocabulary and `docs/adr/` for past decisions. Ask:
1. Does `CONTEXT.md` exist? If not, should one be created by extracting domain concepts from `CLAUDE.md` / `AGENTS.md`?
2. Is this a single-context repo (one `CONTEXT.md` + `docs/adr/` at root) or multi-context (e.g. monorepo with per-package contexts)?
3. Should `docs/adr/` be created now if it doesn't exist?

**After all three sections**, confirm the full plan with the user, then write:
- `CONTEXT.md` (if needed)
- `docs/agents/issue-tracker.md`
- `docs/agents/triage-labels.md`
- `docs/agents/domain.md`
- `docs/adr/.gitkeep` (if requested)
- An `## Agent skills` block in `CLAUDE.md` (preferred) or `AGENTS.md`

Then resume the PRD process from step 1.

## PRD template

<prd-template>

## Problem Statement

The problem the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories — extremely extensive, covering all aspects of the feature. Format each as:

1. As an <actor>, I want a <feature>, so that <benefit>

Example: "As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending"

## Implementation Decisions

The implementation decisions that were made, such as: modules to build/modify, the interfaces of those modules, technical clarifications from the developer, architectural decisions, schema changes, API contracts, specific interactions.

Do NOT include specific file paths or code snippets — they may become outdated quickly. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it within the relevant decision and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

## Testing Decisions

The testing decisions that were made. Include: what makes a good test (only test external behavior, not implementation details), which modules will be tested, and prior art for the tests (similar tests in the codebase).

## Out of Scope

The things that are out of scope for this PRD.

## Further Notes

Any further notes about the feature.

</prd-template>
