# Maintainer Guide: Authoring Skills

Skills live in `claude/skills/<name>/`, symlinked into `~/.claude/skills/`.

## 1. Anatomy & token economics

- **Directory name = skill name.** One skill per directory.
- **`SKILL.md`** is loaded into context in full on every invocation. Every byte costs tokens every time.
- **Frontmatter `description`** is loaded into EVERY session (invoked or not) — it's how the model decides to trigger the skill. Keep it tight but complete.
- **Auxiliary `.md` files** (e.g. `tdd/tests.md`, `tdd/mocking.md`) cost nothing until the executor is told to read them.
- **Scripts** cost ~0 tokens (only their invocation line in SKILL.md).

## 2. Frontmatter rules

- `---` MUST be the literal first line of SKILL.md. **Real bug here:** an HTML comment placed before it silently broke frontmatter parsing — the skill lost its trigger description and never fired. Attribution comments (`<!-- imported from: ... -->`) go AFTER the closing `---`.
- Required keys: `name:` (must equal the directory name) and `description:`.
- `description` = what the skill does + when to trigger, including literal trigger phrases in quotes (see handoff: `Use when the user says "handoff", "hand off", ...`). Quote the whole value if it contains colons/apostrophes (see llm-council).
- Optional: `argument-hint:` (see handoff).

## 3. Writing style

Write for a weak executor running cold, with zero context:

- Imperative voice, numbered steps, explicit checklists.
- Specify output formats exactly (research's Codemap table; handoff's filename pattern).
- No ambiguity: say "Launch ALL subagents in a single message", not "consider parallelism".
- **Preserve behavior over brevity.** When unsure whether a line matters, KEEP it. Never pad, but never trim a rule you can't prove is dead.
- Add anti-patterns/scope checks where misfiring is likely (tdd's "Anti-Pattern: Horizontal Slices"; llm-council's "Scope check").

## 4. Progressive disclosure

- Content needed on EVERY invocation → merge into SKILL.md.
- Content needed SOMETIMES → aux file, with an explicit conditional read instruction in SKILL.md: "Before adding ANY mock, read [mocking.md](mocking.md)" — always "read X when Y", never a bare link.
- No dead links: after editing, `ls` the skill directory and verify every referenced file exists.

## 5. Validation checklist (run after ANY skill change)

1. Line 1 of SKILL.md is exactly `---`; nothing (comments included) precedes it.
2. Frontmatter parses as YAML; `name` matches the directory name; `description` present with trigger phrases.
3. Every file referenced in SKILL.md exists (`ls` the directory).
4. Diff against git history (`git diff HEAD -- claude/skills/<name>/`): every old behavior, rule, threshold, and output format is present or deliberately removed with justification.
5. Attribution comment (if any) sits after the closing `---`.

## 6. Multi-agent authoring/review workflow

For any new or changed skill, spawn subagents in this sequence:

**(a) Author/optimizer agent** — writes or rewrites the skill per sections 1–4: correct frontmatter, imperative steps, progressive disclosure, no behavior loss.

**(b) Two adversarial reviewers, in parallel:**

- **Fidelity reviewer.** Charter: diff against `git show HEAD:claude/skills/<name>/SKILL.md` (and aux files). Assume behavior WAS lost and try to prove it — enumerate every old rule, step, threshold, trigger phrase, and output format and locate each in the new version. Report anything missing or weakened as a blocker.
- **Executability reviewer.** Charter: simulate a weak model executing the skill cold — no repo or conversation context. Walk each step literally: is every instruction actionable? Outputs fully specified? Referenced files exist? Would frontmatter parse and trigger? Report any ambiguity, dead link, or unstated assumption as a blocker.

**(c) Fix agent** — applies both blocker lists, then re-runs the section 5 checklist.

Give each agent one task and absolute paths; require findings back as text (blocker/non-blocker lists), not files.
