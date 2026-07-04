---
name: skill-cleaner
description: "Audit Claude Code/Codex/OpenClaw skills: loaded roots, duplicate skills, unused skills, prompt-budget costs, compact descriptions. Use when the user wants to trim skill prompt budget, find duplicate or unused skills, audit enabled/disabled skill roots, decide which skills/plugins to remove, or says \"clean up my skills\" or \"audit my skills\"."
---
<!-- imported from: https://github.com/steipete/agent-scripts/blob/main/skills/skill-cleaner/SKILL.md -->

# Skill Cleaner

## Workflow

1. Run the analyzer. Run it from this skill's directory (the directory containing this SKILL.md) so the `scripts/` path resolves, or pass an absolute path to `scripts/skill-cleaner.ts` from anywhere. Default roots cover only Codex (`~/.codex/skills`, `~/.codex/plugins/cache`, `~/Projects/*/.agents/skills`) — for Claude Code you must add `--root ~/.claude/skills` (and any project `.claude/skills` dirs):

```bash
node --experimental-strip-types scripts/skill-cleaner.ts --months 3 --root ~/.claude/skills
```

If the report shows `skills: 0 discovered`, re-run with `--root` pointing at the skill roots actually in use.

Useful variants:

```bash
node --experimental-strip-types scripts/skill-cleaner.ts --no-logs
node --experimental-strip-types scripts/skill-cleaner.ts --months 6 --max-log-mb 800 --deep-logs
node --experimental-strip-types scripts/skill-cleaner.ts --context-tokens 272000 --budget-percent 2 --no-logs
node --experimental-strip-types scripts/skill-cleaner.ts --root ~/Dropbox/boxd/skills --no-logs
```

2. Read the report sections in this order:
- `Skill Budget`: GPT-5.5 context size, 2% skills budget, Codex-budgeted usage, and pre-budget full-list pressure.
- `Description Candidates`: long descriptions where relaxed grammar saves prompt budget.
- `Duplicates By Name` / `Duplicates By Body Hash` / `Duplicate Delete Suggestions`: same skill name or near-identical description/body across Codex, plugin cache, repo siblings, and personal skill roots, plus which copies to delete.
- `Unused Candidates`: no recent `$skill` mention, `SKILL.md` read, or explicit skill-use trace in recent Codex/OpenClaw logs.
- `Root Summary`: where skills came from and whether config marks them disabled.

3. Before deleting or editing any skill:
- Verify the kept copy exists (`ls` its `SKILL.md`) and appears in the report's `Root Summary` without a disabled count against its root.
- Prefer deleting repo-local or `agent-scripts` duplicates when Codex built-ins cover them.
- Keep repo-local OpenClaw maintainer skills when they encode repo policy or live operations.
- When shortening a description, preserve its trigger nouns: product, tool, action, object.

## Analyzer Notes

- The script mirrors Codex's model-visible line shape: `- name: description (file: path)`.
- It applies Codex-like frontmatter rules: YAML frontmatter only, default name from parent dir, single-line sanitized `name` and `description`.
- It follows Codex `core-skills/src/render.rs`: 2% of raw `context_window`, token cost `ceil(utf8_bytes / 4)`, then full descriptions -> equal description truncation -> omitted minimum lines.
- It reads `~/.codex/models_cache.json` for GPT-5.5 `context_window`; fallback is 272,000 tokens and 2%.
- It scans only normal Codex/plugin/repo skill roots by default. Claude Code roots (`~/.claude/skills`, project `.claude/skills`) and extra folders such as Dropbox archives are included only with `--root <path>`.
- It realpath-dedupes roots, so symlinked roots such as `~/.codex/skills/agent-scripts -> ~/Projects/agent-scripts/skills` do not create false duplicates.
- For duplicate names, it reports description/body similarity and suggests deletion candidates only when bodies are near copies. Keep priority defaults to direct Codex system skills, then direct Codex skills, then plugin skills, then personal/repo copies.
- It scans `~/.codex/history.jsonl` and recent `~/.codex/sessions/**/*.jsonl` by default. Add `--deep-logs` for archived sessions and common OpenClaw/Clawd log folders.
- Usage evidence is heuristic: `$skill`, `Use $skill`, and paths like `skills/<name>/SKILL.md`.

## Output Policy

- Suggest first; edit only when the user asks.
- If asked to apply cleanup, make small grouped commits: descriptions, deletes, config disables.
- Do not delete ignored/untracked skill dirs without naming the destination or confirming they are disposable.
