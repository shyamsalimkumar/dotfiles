---
name: set-git-rules
description: Session-scoped git workflow rules for implementation work - worktrees, per-task branch questions, subject-only commits, no pushing, and a fixed branch topology for multi-issue PRDs. Only activates when the user explicitly says "set git rules" or invokes this skill by name.
---

# Set Git Rules

Opt-in only: activate only when the user explicitly says "set git rules" or invokes this skill by name — never infer activation from task shape. Once active, apply these rules to every commit-producing task for the rest of the session. No re-invocation needed; no off-switch until the session ends.

## Commit messages

- Subject line only: no body, no footer, no Conventional Commits prefix.
- No attribution trailers ("Generated with Claude Code", Co-Authored-By, etc).
- Imperative mood, concise, roughly under 72 chars.

## Never push

Never run `git push` unprompted. Pushing is fine only when the user explicitly asks for it.

## Never empty commits

Never create an empty commit (`git commit --allow-empty` or a commit with no staged changes). If a task produces no actual changes to commit, say so and skip the commit — do not manufacture a placeholder commit to mark progress.

## Ask before every task

Before touching git, for every task — even the second one in the same session, never reusing a previous answer:
1. Ask the user for the base branch.
2. Ask the user for the branch name.

Then, before creating anything, print a pre-flight summary: base branch, integration branch (if multi-issue), every branch name, every worktree path. This lets the user catch a bad name before any git state exists.

## Always work in worktrees

- Before branching, `git fetch` the base branch's remote so you build on current state, not stale local state.
- Worktree location: `./worktrees/<branch>` if the repo's `.gitignore` covers it; otherwise `~/worktrees/<project>-<branch>`. Check `.gitignore` yourself and fall back automatically — do not ask.
- If the target worktree path or branch name already exists: stop and ask the user how to proceed (reuse, remove, or rename). Never silently overwrite or delete unknown state.
- While these rules are active, create and remove worktrees/branches without per-action confirmation — that standing authorization is the point of turning them on.

## Single issue

One branch off the named base branch, checked out in one worktree. No integration-branch wrapper. After the commit:
1. Remove the worktree.
2. Leave the branch unmerged and unpushed, for the user to review or PR themselves.

## Multiple issues

Treat a task as multi-issue only when it arrives as a pre-split list (a PRD, to-prd output, or an explicit list from the user). Never split a single free-form request on your own judgment.

Topology:
- One integration branch (the name the user gave you, e.g. `feature-name`) off the named base branch, with its own worktree.
- One section branch per issue, named after that issue's title/description (e.g. `feature-name-<issue-slug>`), branched off the integration branch, each with its own worktree.
- Assume issues are independent and implement them in parallel via separate subagents. Exception: if the PRD/list explicitly states a dependency, implement the dependent issues sequentially, in dependency order.

Per issue, once its implementation is committed:
1. Rebase the section branch onto the current tip of the integration branch.
2. Fast-forward merge it into the integration branch.
3. Delete the section branch and remove its worktree immediately — do not wait for other sections to finish.

If a rebase conflicts: try to resolve it yourself. If you cannot resolve it confidently, stop and report the conflict to the user rather than guessing.

Never merge the integration branch into the true base and never push it — that is the user's call, made later (e.g. via a PR).

## When everything lands

Remove the integration branch's worktree; leave the integration branch itself unmerged and unpushed.

State plainly what happened and what did not: which branch holds the work (the integration branch for multi-issue, the single branch otherwise), that nothing was pushed, and that nothing was merged into the true base — the user still needs to review and push/PR it themselves.
