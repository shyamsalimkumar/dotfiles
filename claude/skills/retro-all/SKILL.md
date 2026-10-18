---
name: retro-all
description: "Retrospective across all recent sessions: find recurring friction and propose commands, skills, checks or config to remove it."
disable-model-invocation: true
argument-hint: "[days, default 30]"
---

The user has asked for a **retrospective** over many sessions at once. `retro` looks at one session; you look for **recurring friction**: the same prompt, correction, error, or tool sequence showing up across sessions. One session's struggle is noise; the same struggle in three sessions is a fix worth building. You only propose: nothing changes until the user picks a candidate.

## Steps

1. Call the Skill tool with `writing-for-agents`; every skill, command or steering line you propose follows it.

2. **Digest.** Shrink the logs into your scratchpad directory (or a fresh `mktemp -d` folder) (days = `$ARGUMENTS`, or 30 if empty; `0` means all):

   ```bash
   python3 ~/.claude/skills/retro-all/scripts/digest.py <scratchpad>/retro-all/digests --days <days> > <scratchpad>/retro-all/index.tsv
   ```

   Each digest is one session: `USER:` prompts, `CALL` tool calls, `ERROR` tool failures. `index.tsv` columns: batch, path, project, date, title, bytes. Done when `index.tsv` exists; tell the user how many sessions and batches it holds.

3. **Inventory** what already exists, so a candidate reuses or sharpens it before inventing a new one: names and descriptions of every skill in `~/.claude/skills/` and enabled plugins, `~/.claude/commands/`, hooks and permissions in `~/.claude/settings.json`, `~/.claude/CLAUDE.md`, and the `scripts/` and `zsh/` folders of the dotfiles repo (`~/Projects/github.com/shyamsalimkumar/dotfiles`). Keep this as a short list in your own context.

4. **Read.** Launch one subagent per batch, ALL in a single message, each with the batch's digest paths and the reader brief below. Done when every batch has reported back.

5. **Merge.** Join the readers' findings that describe the same pattern. A candidate needs **two or more sessions** of evidence. Check each against the inventory: when an existing skill or command already covers it, the candidate is "it never fired" (sharpen its description or trigger) or "it fired and failed" (fix it), never a duplicate. Done when every reader finding is merged, covered, or dropped for single-session evidence.

6. **Present** the candidates, ranked by sessions × cost per occurrence (wasted tool calls, user retyping, interruptions). For each give:
   - **Pattern**: what keeps happening, in one line.
   - **Evidence**: session count, and two or three session titles with the quoted line.
   - **Fix**: the fix type from the table below, and the exact file it lands in.

   Then ask which to build. Build a picked machine-wide fix in the dotfiles repo following its `AGENTS.md` (branch, verify, PR); a fix for one project goes in that project's repo.

## Fix types

| What recurs | Fix |
| --- | --- |
| The user types the same instruction or ritual (`merge it`, `test`, a pasted checklist) | A **slash command** in `claude/commands/`, or a user-invoked skill when it has several steps |
| The agent runs the same multi-step tool sequence by hand | A **script** the agent calls, or a skill that wraps it |
| The user corrects the agent the same way | A **check** (hook, lint, test) when mechanical; a rule in the reviewer's standards when a judgement call; a `CLAUDE.md` line only as a last resort |
| The same tool error or retry (missing binary, wrong flag, bad path) | Fix the environment: install via `nix/home.nix`, alias in `zsh/`, or a pointer to the right command |
| The same permission prompt or user interruption | An allowlist entry in `claude/settings.json` (the `fewer-permission-prompts` skill does this) |
| The agent hunts for the same fact or file | A **navigation pointer** from a file it already reads |
| The agent needs information it cannot reach | Widen access: a log file, a read-only CLI or MCP server |
| Sessions keep running out of context on one kind of task | Split the task: a hand-off skill, or a subagent step |
| An existing skill or steering line never changes behaviour | Delete it (a **no-op**) |

## Reader brief

Give each reader this brief, with its digest paths filled in:

> You are reading Claude Code session digests to find **recurring friction**. Read every line of every file listed below (use offset/limit on files too large for one read). Lines are `USER:` (what the user typed), `CALL` (a tool call), `ERROR` (a failed tool call).
>
> Look for: prompts the user repeats; corrections ("no", "I said", "again", "why did you"); interruptions; the same error or retry; the same chain of 3+ calls doing one job; long searches for one fact; requests the agent could not serve; sessions continued after running out of context.
>
> Report each pattern as:
> `PATTERN: <one line> | KIND: <prompt / correction / error / sequence / search / access / context> | SESSIONS: <session-id: quoted line>; ...`
>
> Report a pattern even if it appears in only one of your sessions; the merge step counts across batches. Done when every file has been read; end with `READ: <n> of <n> files`.
>
> Files:
> <paths>
