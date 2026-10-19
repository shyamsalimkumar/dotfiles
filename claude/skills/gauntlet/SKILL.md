---
name: gauntlet
description: Do a coding task, then run it past a fresh checker subagent each round until it passes (max 3 rounds).
disable-model-invocation: true
argument-hint: "<task>"
---

# Gauntlet

You are the **builder**. Each round, a fresh **checker** subagent judges your work and returns a **verdict**. The checker is fresh every round so it judges the code, never your reasoning or its own earlier verdict.

The task is `$ARGUMENTS`. If it is empty, ask for the task before starting.

## 1. Set the base

Run `git rev-parse HEAD` and keep the hash as `<base>`. If `git status --porcelain` shows changes, ask whether they belong to the task; the checker will see them as part of the diff.

## 2. Build

Do the task the way you normally would, tests included. Done when you believe the task is complete and the project's checks are green.

## 3. Run the gauntlet

Up to 3 rounds. Each round, dispatch a new `general-purpose` subagent with the checker prompt below, filled in. Pass the task verbatim, never your summary of it, so the checker judges against what was asked.

- **PASS**: stop and go to step 4.
- **FAIL**: fix every finding, then start the next round. If a finding is wrong, leave the code and add it to `Disputed` in the next checker prompt with your reason; the next checker rules on it.
- **FAIL on round 3**: stop and go to step 4.

### Checker prompt

```
You are the checker in a gauntlet. Judge the work below; leave the working tree exactly as you found it.

Task (verbatim from the user):
<task>

Repo: <absolute repo path>
Base commit: <base>
See the change with `git status` and `git diff <base>`; read untracked files directly.

Disputed findings from the last round (rule on each: upheld or dropped):
<none, or each finding with the builder's reason>

Judge on exactly two things:
1. Green: run the project's checks for every language the diff touches, following ~/.claude/skills/<lang>-check/SKILL.md (go, js, python, rust), or the repo's own check command if it has one. Any failure is a finding.
2. Matches the task: every requirement in the task is done, and the diff holds nothing the task did not ask for. Each missing or extra piece is a finding.

Reply in exactly this shape:
VERDICT: PASS or FAIL
FINDINGS:
- <file:line> <what is wrong> | <why it fails check 1 or 2>
(write "none" when PASS)

PASS means zero findings.
```

## 4. Report

Tell the user:

- The final verdict and how many rounds it took.
- On FAIL after round 3: the findings still open, and which ones you disputed.
- What changed, in one or two lines. Nothing is committed; the user decides that.
