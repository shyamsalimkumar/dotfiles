# import-skill

Import a Claude Code skill from an external source into `~/.claude/skills/`.

## Invocation

`/import-skill <source> [skill-name]`

- `<source>`: local path, GitHub repo URL, GitHub gist URL, or raw URL pointing to a `SKILL.md`
- `[skill-name]`: optional override for the destination directory name

## What to do

### 1. Parse the source

Determine the source type:

- **Local path** — a filesystem path to either a `SKILL.md` file or a directory containing one.
- **GitHub repo URL** — e.g. `https://github.com/user/repo` or `https://github.com/user/repo/tree/branch/path`. Look for a `SKILL.md` at the given path, or if the URL is a repo root, check `SKILL.md` then `.claude/skills/*/SKILL.md`.
- **GitHub gist URL** — e.g. `https://gist.github.com/user/<hash>`. Fetch the raw gist content via `https://gist.githubusercontent.com/user/<hash>/raw/`.
- **Raw URL** — any other `https://` URL. Fetch directly with `curl -fsSL`.
- **GitHub shorthand** — e.g. `user/repo` or `user/repo/path/to/SKILL.md`. Treat as a GitHub URL.

### 2. Fetch the content

- **Local path**: read the file with the Read tool.
- **GitHub repo**: convert the URL to a raw `https://raw.githubusercontent.com/` URL then `curl -fsSL` it.
  - Branch defaults to `main`, fall back to `master` if 404.
  - If the URL is a repo root (no file path), try `SKILL.md` first, then probe `.claude/skills/` for subdirectories and list them for the user to choose, or import all if there is only one.
- **Gist**: `curl -fsSL https://gist.githubusercontent.com/<user>/<hash>/raw/`
  - If the gist has multiple files, list them and ask which to import (or import the first `SKILL.md` file found automatically).
- **Raw URL**: `curl -fsSL <url>`

### 3. Determine the skill name

Priority order:
1. The `[skill-name]` argument if provided.
2. The `name:` field in the fetched content's YAML frontmatter (if present).
3. The parent directory name of the source path/URL.
4. Ask the user.

Sanitize: lowercase, hyphens only, no spaces.

### 4. Check for conflicts

If `~/.claude/skills/<skill-name>/SKILL.md` already exists:
- Show a diff of existing vs new content.
- Ask the user whether to overwrite, rename, or cancel.

### 5. Prepend source attribution

If the source is not a local path, prepend a comment block to the SKILL.md content before saving:

```
<!-- imported from: <original-url> -->
```

Place it as the very first line so it is visible but does not break any frontmatter (YAML frontmatter starts with `---`, so prepend before that if present, or before the first heading otherwise).

If the content already has an `imported from` comment, update it.

### 6. Write the file

Write the (possibly modified) content to `~/.claude/skills/<skill-name>/SKILL.md`.

Create the directory if it does not exist.

### 7. Confirm

Report:
- The skill name and destination path.
- The source URL (linked, if remote).
- Any modifications made (attribution line added, etc.).

Do NOT restart or reload — Claude Code picks up new skills on the next invocation automatically.

## Edge cases

- If `curl` returns a non-200 / empty body, report the error clearly and stop.
- If the fetched content does not look like a skill (no headings, suspiciously short, binary), warn the user and ask for confirmation before writing.
- If the source is a GitHub repo with multiple skills under `.claude/skills/`, import them all by default but confirm with the user first.
