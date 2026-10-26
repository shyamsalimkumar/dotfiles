---
name: learnings
description: 'Read and record lessons agents learn across all projects, in the "Project ideas" Obsidian vault: one note per lesson, linked from the vault INDEX.md and from the project''s hub note. Use at the start of a task to read past lessons for the project, and right away when the user corrects you, the same mistake happens twice, a workaround or a better technique is found, or the user says "remember this", "learn from this", "add a learning", "note this lesson" or "don''t do that again".'
---

# Learnings

Lessons live in an Obsidian vault so the user can browse them and every agent can read them. Each lesson is its own note, linked both ways: from the vault index and from the project it came from.

`VAULT` below means:

```
$HOME/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/Project Ideas/Project ideas
```

The path has spaces: always quote it. If `VAULT` does not exist (a work machine, iCloud not synced), say so in one line and skip this skill; never create the vault.

## Vault layout

- `INDEX.md`: the entry point. A project list, then a `## Learnings` section with one line per lesson.
- `<Project>/<Project>.md` (or `<Project>.md` at the root, like `Hive.md`): the project's hub note. Its `Repo:` line holds the repo path. It has a `## Learnings` section with one line per lesson for that project.
- `Learnings/<YYYY-MM-DD> <Title>.md`: one note per lesson. The date prefix keeps file names unique.

Links are relative markdown links with spaces written as `%20`, for example `[Homelab](Homelab/Homelab.md)` or `[Never print secrets](Learnings/2026-10-26%20Never%20print%20secrets.md)`. Never wikilinks; the vault is also read outside Obsidian.

## A. Read (start of a task)

1. Read `VAULT/INDEX.md`, the `## Learnings` section.
2. Find the project's hub note. Get the repo folder name with `basename "$(git rev-parse --show-toplevel)"`, then `grep -rlE "Repo:.*/<name>\`" "VAULT" --include='*.md'`. No match: look for a hub file named after the project (`ls "VAULT"`). Still none: the project has no lessons yet.
3. Read the hub note's `## Learnings` section.
4. Open only the lesson notes whose titles fit the task. Follow them.

## B. Record (when a lesson happens)

A lesson is worth a note when it would change what an agent does next time: a correction from the user, a mistake made twice, a workaround, a tool or API surprise, or a technique that worked better. Not worth a note: a one-off typo, a fact already in the repo's docs or `AGENTS.md`.

Record it the moment it happens, not at the end of the session.

1. **Check for an existing note.** `grep -ril "<two or three key words>" "VAULT/Learnings"`. If one covers it, update that note (add detail, add this project to its `Projects:` line and frontmatter) and skip to step 4 for the new project only.
2. **Find the project hub** (step A.2). No hub yet: create `VAULT/<Project>/<Project>.md` with the frontmatter below, a one-line description, a `Repo:` line, an empty `## Learnings` section and `Up: [Project ideas](../INDEX.md)`, then add it to the project list in `INDEX.md` in the same form as the other projects. `<Project>` is the repo folder name in Title Case.
3. **Write the note** at `VAULT/Learnings/<today> <Title>.md`. The title is the rule itself, short, no colons or slashes (`Never print a secret to check it`). Use exactly this shape:

   ```markdown
   ---
   title: <Title>
   date: <YYYY-MM-DD>
   tags: [learning, <mistake|technique>, <topic>]
   projects: [<Project>]
   ---

   # <Title>

   **Rule:** <one sentence an agent can follow>

   **What happened:** <two or three sentences: what went wrong or what was found, and the cost>

   **How to apply:** <when this comes up, and what to do instead>

   Projects: [<Project>](../<path to hub>)

   Up: [Project ideas](../INDEX.md)
   ```

   Plain words, short sentences, no em dashes. Never write a secret, token or private data into a note.

4. **Link it both ways**, one line each in the form `- [<Title>](<relative link>): <Rule>`:
   - In `VAULT/INDEX.md` under `## Learnings` (create the section at the end, before any `Up:` line, if missing).
   - In the hub note under `## Learnings` (create it before the `Up:` line if missing).
   Newest lines go at the top of each section.
5. **Check the links.** Every link you wrote must point to a file that exists: `ls` each target. If the obsidian-notes skill is available, also run its lint on `VAULT`.
6. Tell the user in one line: the note's title and that it's linked from the index and the project.
