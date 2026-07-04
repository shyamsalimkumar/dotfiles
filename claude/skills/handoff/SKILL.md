---
name: handoff
description: Compact the current conversation into a handoff document a fresh agent can pick up and continue from. Use when the user says "handoff", "hand off", "write a handoff doc", or wants to continue this work in a new session.
argument-hint: "What will the next session be used for?"
---
<!-- imported from: https://github.com/mattpocock/skills/blob/main/skills/productivity/handoff/SKILL.md -->

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save it as `handoff-<short-topic>.md` in the OS temporary directory (e.g. `$TMPDIR` or `/tmp`), not the current workspace, and after writing tell the user the absolute path so they can reference it in the next session.

Rules:
1. Include a "Suggested skills" section listing skills the next agent should invoke.
2. Do not duplicate content already captured in other artifacts (PRDs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.
3. Redact sensitive information: API keys, passwords, personally identifiable information.
4. If the user passed arguments, treat them as a description of what the next session will focus on and tailor the document accordingly.
