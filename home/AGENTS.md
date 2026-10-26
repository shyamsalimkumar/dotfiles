# Agent Instructions

## Workflow
- Plan first for any task with 3+ steps or an architectural decision. When something goes sideways, stop and re-plan.
- Delegate research, exploration and parallel analysis to subagents, one focused task each, to keep the main context clean.
- Given a bug report, fix it autonomously: read the logs, errors and failing tests, then resolve them. Write the failing test that reproduces it.
- Prefer TDD (red, green, refactor) for features and bug fixes; skip it only for exploratory work and prototypes.
- If the project has a `tasks/` folder, plan non-trivial work in `tasks/todo.md` as checkable items and tick them off as you go.
- Lessons go in the Obsidian vault, following `~/.claude/skills/learnings/SKILL.md`: read the past lessons for the project at the start of a task, and record a new one the moment you are corrected, repeat a mistake, or find a workaround or better technique. At the end of a task that starts or finishes an idea on the vault's `Ideas.md`, update it there; add a new idea only when the user asks.
- Before calling a task done, prove it works: tests pass, behaviour diffed against main when relevant, and the change would pass a staff engineer's review.
- For non-trivial changes, ask whether a more elegant solution exists before presenting; replace hacky fixes with the elegant one.

## Code
- Keep changes surgical: touch only what the task needs.
- Let names carry meaning; write a comment only for the non-obvious why.
- Generated files (`*_gen.go`) are read-only: put the change in a hand-written file instead (e.g. a new struct in `crud.go` beside `crud_gen.go`).
- Leave the tree clean: remove unused variables, params, imports and methods you introduced, inline single-use variables, and delete build outputs and temp files.
- After editing code, follow the matching checklist in `~/.claude/skills/<go|python|js|rust>-check/SKILL.md`.

## Asking
Ask when requirements conflict, the choice is architectural or hard to reverse, the request may not solve the real problem, or security or data loss is at stake. Otherwise pick the conventional default and proceed.

## Git
- Commit messages and PR descriptions carry no AI attribution (no Co-Authored-By, no "Generated with").
- A session the desktop app already started in a worktree (`.claude/worktrees/...`) works there and makes no second one. A worktree you create yourself goes at `./worktrees/<branch-name>` inside the repo (git-ignored globally).

## Writing
Use a single dash (-), comma or semicolon where an em dash would go; never write em dashes.
