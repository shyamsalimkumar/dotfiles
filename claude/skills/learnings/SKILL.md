---
name: learnings
description: 'Read and record lessons agents learn across all projects, in the "Project ideas" Obsidian vault: one note per lesson, linked from the vault INDEX.md and from the project''s hub note. Also keeps the vault''s Ideas.md list current. Use at the start of a task to read past lessons for the project, and right away when the user corrects you, the same mistake happens twice, a workaround or a better technique is found, or the user says "remember this", "learn from this", "add a learning", "note this lesson" or "don''t do that again". Also when work builds or starts an idea on Ideas.md, or the user says "add this to my ideas". Also whenever a project's design is discussed or decided (a game's story, art style, economy, characters, monsters, levels; an app's screens or rules), to keep it as design notes in the vault.'
---

# Learnings

Lessons live in an Obsidian vault so the user can browse them and every agent can read them. Each lesson is its own note, linked both ways: from the vault index and from the project it came from.

`VAULT` below means:

```
$HOME/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/Project Ideas
```

The path has spaces: always quote it. If `VAULT` does not exist (a work machine, iCloud not synced), say so in one line and skip this skill; never create the vault.

## Vault layout

- `INDEX.md`: the entry point. A link to `Ideas.md`, a project list, then a `## Learnings` section with one line per lesson.
- `Ideas.md`: every project idea, in three sections: `## Built` (crossed out), `## Started or partly built`, `## Not started`. See part C.
- `<Project>/<Project>.md` (or `<Project>.md` at the root, like `Hive.md`): the project's hub note. Its `Repo:` line holds the repo path. It has a `## Learnings` section with one line per lesson for that project.
- `Learnings/<YYYY-MM-DD> <Title>.md`: one note per lesson. The date prefix keeps file names unique.
- `<Project>/<Project> - <Topic>.md`: the project's design notes, one per topic (`Hive - Story.md`, `Hive - Economy.md`), linked from the hub note's `## Design` section. See part D.

Links are relative markdown links with spaces written as `%20`, for example `[Homelab](Homelab/Homelab.md)` or `[Never print secrets](Learnings/2026-10-26%20Never%20print%20secrets.md)`. Never wikilinks; the vault is also read outside Obsidian.

## A. Read (start of a task)

1. Read `VAULT/INDEX.md`, the `## Learnings` section.
2. Find the project's hub note. Get the repo folder name with `basename "$(git rev-parse --show-toplevel)"`, then `grep -rlE "Repo:.*/<name>\`" "VAULT" --include='*.md'`. No match: look for a hub file named after the project (`ls "VAULT"`). Still none: the project has no lessons yet.
3. Read the hub note's `## Learnings` and `## Design` sections.
4. Open only the lesson and design notes whose titles fit the task. Follow them.

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

## C. Ideas (`VAULT/Ideas.md`)

The list belongs to the user. Agents keep existing ideas current; they never add new ones on their own.

1. **At the end of a task**, read `VAULT/Ideas.md`. If the work just started or finished an idea on it, update that idea:
   - Started: move it to `## Started or partly built` and add its project link and what is built so far.
   - Finished: move it to `## Built`, write it as `- [x] ~~<idea>~~ <project link>`, and say in a few words anything from the idea that was left out.
   - Partly built and more got done: update the "what is built" words.
2. **Project links:** the project's hub note when there is one (`[Homelab](Homelab/Homelab.md)`), else `Repo: [<name>](https://github.com/shyamsalimkumar/<name>)` when the repo is on GitHub, else the repo path in backticks.
3. **New ideas:** add one only when the user asks ("add this to my ideas", "put that on the list"). Write it in their words, under `## Not started`, or under `## Started or partly built` with its link if a project already covers it. An idea you thought of yourself: mention it to the user in one line, and don't write it.
4. Check every link you wrote, as in step B.5, and tell the user in one line what changed on the list.

## D. Design notes

When the user and you discuss or decide a project's design, save it in the vault without being asked, so it outlives the chat. Design means what the thing is, not how the code works: for a game, the story, world, characters, monsters, art style, sound, economy, progression and levels; for an app, its screens, flows and rules.

1. **Find or make the hub** (step B.2). No repo yet: make the hub anyway, with `Repo: none yet`, and fix the line once a repo exists. If an `Ideas.md` line covers the project, link the hub from it.
2. **One note per topic** at `VAULT/<Project>/<Project> - <Topic>.md`, with the frontmatter `title`, `date`, `tags: [design, <project>, <topic>]`, then the content, then `Up: [<Project>](<relative link to the hub>)`. Split a topic that grows past a screen or two (`Hive - Monsters.md` out of `Hive - World.md`).
3. **Write the current design, not the chat.** Each note says what was decided, with a short why for anything not obvious. When a decision changes, edit the note to the new one and keep the old one in a `## Changed` list at the end (`2026-10-26: gold drops halved, the early game was too easy`). Open questions go in a `## Open questions` list.
4. **Images and assets are links, never copies.** Big files would fill iCloud. Keep art, sprites, sounds and mockups in the repo (or wherever they already live) and link to them: the GitHub URL when the repo is on GitHub, else the path in backticks, or the web URL for a reference found online. Describe in words what each one shows, since the image won't show in the vault.
5. **Link it** from the hub note's `## Design` section (create it before `## Learnings`, or before `Up:`), one line per note: `- [<Topic>](<relative link to the note>): <one line on what it covers>`.
6. **Save as you go**: after each decision, not at the end of the session. Check the links (step B.5) and tell the user in one line which notes changed.
