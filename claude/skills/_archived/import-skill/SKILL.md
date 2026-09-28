---
name: import-skill
description: Import a Claude Code skill from an external source (local path, GitHub repo/gist, or raw URL) into ~/.claude/skills/. Use when the user says "import skill", "install this skill", "add skill from <url>", or invokes /import-skill.
argument-hint: <source> [skill-name]
---

# import-skill

Import a skill into `~/.claude/skills/<skill-name>/SKILL.md`. `[skill-name]` overrides the destination directory name.

## Steps

### 1. Parse the source type

- **Local path** — filesystem path to a `SKILL.md` or a directory containing one.
- **GitHub repo URL** — e.g. `https://github.com/user/repo` or `.../tree/branch/path`. Look for `SKILL.md` at the given path; if the URL is a repo root, check `SKILL.md` then `.claude/skills/*/SKILL.md`.
- **GitHub gist URL** — e.g. `https://gist.github.com/user/<hash>`.
- **GitHub shorthand** — `user/repo` or `user/repo/path/to/SKILL.md`. Treat as a GitHub repo URL.
- **Raw URL** — any other `https://` URL.

### 2. Fetch the content

- **Local path**: read with the Read tool.
- **GitHub repo**: convert to `https://raw.githubusercontent.com/...` and `curl -fsSL` it. Branch defaults to `main`; on 404 retry `master`. If the URL is a repo root (no file path), try `SKILL.md` first, then list skill subdirectories via `curl -fsSL https://api.github.com/repos/<user>/<repo>/contents/.claude/skills` (read the `name` fields in the JSON array). If exactly one skill is found, import it directly; if several, list them and ask whether to import all or a subset.
- **Gist**: list the gist's files via `curl -fsSL https://api.github.com/gists/<hash>` (keys of the `files` object). If there is one file, or exactly one named `SKILL.md`, fetch it via `curl -fsSL https://gist.githubusercontent.com/<user>/<hash>/raw/<filename>`; otherwise list the files and ask which to import.
- **Raw URL**: `curl -fsSL <url>`.

If curl returns non-200 or an empty body, report the error clearly and stop.
If the content does not look like a skill (no headings, suspiciously short, or binary), warn the user and get confirmation before writing.

### 3. Determine the skill name

Priority: 1) the `[skill-name]` argument; 2) the `name:` field in the fetched YAML frontmatter; 3) the parent directory name of the source path/URL; 4) ask the user.

Sanitize: lowercase, hyphens only, no spaces.

### 4. Check for conflicts

If `~/.claude/skills/<skill-name>/SKILL.md` already exists: show a diff of existing vs new content, then ask the user whether to overwrite, rename, or cancel.

### 5. Add source attribution (remote sources only)

Skip this step for local paths. Otherwise insert:

```
<!-- imported from: <original-url> -->
```

Placement rules — the comment must NEVER be the first line when frontmatter exists, or YAML parsing breaks and the harness shows the raw comment as the skill description:

- Content starts with `---` frontmatter: insert the comment on its own line immediately AFTER the closing `---`.
- No frontmatter: insert the comment as the first line — and if step 6 adds frontmatter, move it to immediately after the closing `---`.
- An `imported from` comment already exists: update its URL, and if it sits before the frontmatter, move it to immediately after the closing `---`.

### 6. Validate against the authoring checklist

Ensure before saving: line 1 is `---`, and frontmatter has a `name` matching the directory name and a `description` stating what the skill does and when to trigger it. Add or fix missing frontmatter, deriving the description from the skill's own content. If `~/.claude/skills/AUTHORING.md` exists, also make the skill pass its checklist.

### 7. Write the file

Write the (possibly modified) content to `~/.claude/skills/<skill-name>/SKILL.md`, creating the directory if needed.

### 8. Confirm

Report: the skill name and destination path; the source URL (linked, if remote); any modifications made (attribution line, frontmatter fixes, etc.).

Do NOT restart or reload — Claude Code picks up new skills on the next invocation automatically.
