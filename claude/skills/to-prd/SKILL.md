<!-- imported from: https://github.com/mattpocock/skills/blob/main/skills/engineering/to-prd/SKILL.md -->
---
name: to-prd
description: Turn the current conversation context into a PRD and publish it to the project issue tracker. Use when user wants to create a PRD from the current context.
---

This skill takes the current conversation context and codebase understanding and produces a PRD. Do NOT interview the user — just synthesize what you already know.

## Process

1. Explore the repo to understand the current state of the codebase, if you haven't already.

   Read the following files if they exist — they are the authoritative config for this skill:
   - `CONTEXT.md` — domain vocabulary and architecture; use this language throughout the PRD
   - `docs/adr/` — past architectural decisions; respect them
   - `docs/agents/issue-tracker.md` — where and how to write issues
   - `docs/agents/triage-labels.md` — how to express triage state
   - `docs/agents/domain.md` — domain doc layout (single vs multi-context)

   If any of these files are missing, do NOT fall back to `CLAUDE.md` or proceed without them. Instead, run the inline setup below before continuing.

### Inline setup (run if config files are missing)

Explore the repo first, then walk the user through the three decisions **one at a time** — present a section, get an answer, then move to the next. Do not dump all three at once.

**Section A — Issue tracker**

Explain: this is where `to-prd` will write issues. Check `git remote -v` — if the remote is GitHub, propose that as default; if GitLab, propose GitLab. Otherwise offer local markdown.

Choices (in order of preference based on the remote):
- **GitHub** — issues in GitHub Issues, created via `gh issue create`
- **GitLab** — issues in GitLab Issues, created via `glab issue create`
- **Local markdown** — issues as files inside the repo (no external CLI needed)
- **Other** — ask the user to describe the workflow in one paragraph

For local markdown, ask three follow-up questions (one at a time):
1. What path should issue files live under? (e.g. `plans/<feature>/issues/`)
2. What file naming convention? (e.g. numbered `001-slug.md`, flat `slug.md`)
3. How should triage state be tracked? (frontmatter `status:` field, subfolders, or filename prefix like `[ready] 001-slug.md`)

**Section B — Triage label vocabulary**

Explain: these five states drive the triage skill's state machine. For GitHub/GitLab they map to label strings; for local markdown they map to whatever encoding was chosen in Section A.

The five canonical roles and their defaults:
- `needs-triage` — maintainer needs to evaluate
- `needs-info` — waiting on reporter
- `ready-for-agent` — fully specified, AFK-ready
- `ready-for-human` — needs human implementation
- `wontfix` — will not be actioned

Ask: does the user want to override any of these strings/prefixes, or are the defaults fine?

**Section C — Domain docs**

Explain: some skills read `CONTEXT.md` for domain vocabulary and `docs/adr/` for past decisions.

Ask:
1. Does a `CONTEXT.md` exist? If not, should one be created by extracting domain concepts from `CLAUDE.md` / `AGENTS.md`?
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

---

2. Sketch out the major modules you will need to build or modify to complete the implementation. Actively look for opportunities to extract deep modules that can be tested in isolation.

A deep module (as opposed to a shallow module) is one which encapsulates a lot of functionality in a simple, testable interface which rarely changes.

Check with the user that these modules match their expectations. Check with the user which modules they want tests written for.

3. Write the PRD using the template below, then publish it to the project issue tracker. Apply the `ready-for-agent` triage label - no need for additional triage.

<prd-template>

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories. Each user story should be in the format of:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

This list of user stories should be extremely extensive and cover all aspects of the feature.

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it within the relevant decision and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details)
- Which modules will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Out of Scope

A description of the things that are out of scope for this PRD.

## Further Notes

Any further notes about the feature.

</prd-template>
