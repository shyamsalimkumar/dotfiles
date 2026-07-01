---
name: set-git-rules
description: Session-scoped git workflow rules for implementation work - worktrees, per-task branch questions, subject-only commits, no pushing, and a fixed branch topology for multi-issue PRDs. Only activates when the user explicitly says "set git rules" or invokes this skill by name.
---

# Set Git Rules

Explicit, opt-in only. Do not infer activation from task shape - only turn these rules on when the user says something like "set git rules" or invokes this skill directly. Once active, they apply to every commit-producing task for the rest of the session (no re-invocation needed, no off-switch - they last until the session ends).

## Commit messages

- Subject line only. No body, no footer, no Conventional Commits prefix.
- No Claude Code attribution trailer ("Generated with Claude Code", Co-Authored-By, etc).
- Plain imperative mood, short and concise (roughly under 72 chars).

## Never push

Never run `git push` proactively. If the user explicitly asks to push at some point, that's fine - the rule blocks unprompted pushes, not all pushes forever.

## Every task, ask first

Before touching git, for every task (even the second one in the same session):
1. Ask what the base branch is.
2. Ask what the branch name should be.

Don't reuse a previous answer - ask fresh each time.

Then print a pre-flight summary before creating anything: base branch, integration branch (if multi-issue), each branch name, and each worktree path. Let the user catch a bad name before any git state exists.

## Always work in worktrees

- Before branching, `git fetch` the base branch's remote so you're building on current state, not stale local state.
- Worktree location follows the existing worktree-location convention (`./worktrees/<branch>` if the repo's `.gitignore` covers it, otherwise `~/worktrees/<project>-<branch>`). Check `.gitignore` yourself; if `./worktrees/` isn't covered, fall back to `~/worktrees/...` automatically - don't ask.
- If the target worktree path or branch name already exists, stop and ask the user how to proceed (reuse, remove, or rename) - never silently overwrite or delete unknown state.
- Creating and removing worktrees/branches needs no per-action confirmation while these rules are active - that standing authorization is the point of turning them on.

## Single issue

One branch off the named base branch, checked out in one worktree. No integration-branch wrapper. After the commit:
- Remove the worktree.
- Leave the branch as-is - unmerged, unpushed - for the user to review or PR themselves.

## Multiple issues (from a PRD, to-prd output, or an explicit list the user gave you)

Only treat a task as "multiple issues" when it arrives as a pre-split list. Don't split a single free-form request on your own judgment.

Topology:
- One integration branch (e.g. `feature-name`) off the named base branch, with its own worktree. This is the branch you asked the user to name.
- One section branch per issue, named after that issue's title/description (e.g. `feature-name-<issue-slug>`), branched off the integration branch, each with its own worktree.
- Assume issues are independent and implement them in parallel via separate subagents, unless the PRD/list explicitly states a dependency between them - in that case implement the dependent ones sequentially, in dependency order.

Per issue, once its implementation is committed:
1. Rebase the section branch onto the current tip of the integration branch.
2. Fast-forward merge it into the integration branch.
3. Delete the section branch and remove its worktree immediately - don't wait for the other sections to finish.

If a rebase conflicts: try to resolve it yourself. If you can't resolve it confidently, stop and report the conflict to the user rather than guessing.

The integration branch itself is never merged into the true base and never pushed - that's the user's call, made later (e.g. via a PR).

## When everything lands

State plainly what happened and what didn't: which branch now holds the work (the integration branch for multi-issue, the single branch otherwise), and that nothing was pushed and nothing was merged into the true base - the user still needs to review and push/PR it themselves.
