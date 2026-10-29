---
name: foundation-doc
description: 'Write or refresh FOUNDATION.md, the handover doc that lets several agents build one app in parallel without rewriting each other: how each runs its own dev server, who owns which files, tokens, shared components, the data model, known gaps. Use when the user says "foundation doc", "write FOUNDATION.md", "update the foundation", "prep this for parallel agents", or before fanning out page agents after a shared base is built.'
argument-hint: "[path-to-brief]"
---

# Foundation doc

FOUNDATION.md is read by every later agent before it writes code. It tells them what already exists, what they may touch, and how to use it. Write it from what is actually in the repo, never from memory or the brief alone. Do not start dev servers or other long-running processes, and do not commit: leave the doc for the user to review.

## 1. Read the project

1. Find the project root: `git rev-parse --show-toplevel`; if that fails, the nearest directory holding a manifest (`package.json`, `go.mod`, `pyproject.toml`, `Cargo.toml`); else the cwd. Say which in the report. If `FOUNDATION.md` already exists there, read it: you are refreshing it, so keep every rule still true and any hand-added section, and update the rest.
2. Find the brief: `$ARGUMENTS`, else `BRIEF.md`, `SPEC.md` or `docs/brief*`. A README is not a brief. If there is none, do not ask for one; write `No brief: this doc and the code are the source of truth` where the brief would be named.
3. Read the manifest, `AGENTS.md`/`CLAUDE.md`, and list the source tree two levels deep from the project root.
4. Locate, and open at least one file of each (if a category is absent, note it for Known gaps):
   - tokens: CSS variables, Tailwind theme, theme files (UI projects only)
   - shared UI primitives and app-specific components, or for a backend, shared packages/modules (handlers, middleware, clients)
   - app shell / layout / providers / global keyboard shortcuts, and the wrapper every page or route must render inside
   - one reference page or module that shows how everything composes
   - data layer: types, fixtures, selectors, formatters, the single import entry point
   - check scripts (data reconciliation, typecheck, lint, test, build)
5. A shared base is at least one of: shared UI, a shared data layer, an app shell, or shared domain packages. If none exist, stop and tell the user: the doc describes a foundation, it cannot replace building one.
6. Get the agent split: which parallel agents there will be and which routes/folders each owns. Take it from the brief or the user; if neither gives it, ask the user before writing sections 1 and 2. Give each agent its own dev port (foundation's port + 1 upward), build/dist dir, browser debug (CDP) port if screenshots are used, screenshot output dir and notes file.
7. For each build/dist dir: confirm the build config actually reads the variable you will tell agents to set (for example `next.config` reading `NEXT_DIST_DIR`; this is not built into Next.js). If it does not, write that under Known gaps instead of claiming isolation. Check the dir is git-ignored, lint-ignored and pre-listed in any config the tool rewrites for unknown dirs (for example `tsconfig.json` include); if not, list it as a gap for the user to fix.

## 2. Write FOUNDATION.md at the project root

Use exactly these section headings. If a section does not apply, keep the heading and write `None: <one-line reason>`. Every path, command, prop and name must exist in the repo; check each one as you write it. Be terse; prefer tables. Replace every `<...>` placeholder; omit a bullet whose value is "none".

```markdown
# <Project> foundation: read this before you build a page

<2-4 lines: stack and versions, what the foundation already built, the reference page/module, and that the brief (path) is the source of truth.>

- Notes / design decisions: <path>
- Reference screens: <screenshot paths>

## 1. Run your own dev server
<Table: agent | dev command with its own port and build dir | debug/CDP port | screenshot dir | notes file.
Which ports and dirs belong to the foundation (do not touch). Screenshot command if one exists.
Option if build dirs cannot be isolated: agents share one dev server and skip the production build; the orchestrator builds at the end.
Check commands that must pass before an agent reports, and when to run each (e.g. "data check if you touch src/data").>

## 2. File layout and ownership
<Tree from the source root, each folder tagged [foundation], [<agent>], "stub - REPLACE (<agent>)" or "unowned - leave or improve".>
**Ownership rule.** Shared folders: <every [foundation] folder>. Agents may add new files anywhere and add exports to a shared file. They must not change existing shared components, tokens or data values; if something is missing or wrong, add alongside it and list it in the report. Commit only files you created or own; never stage another agent's or the foundation's paths, or config the tool rewrote. Delete the placeholder/stub when your page lands. Each agent's pages live in <route dir> and <feature dir>.
**Conventions** <import style, file naming, server/client split, class merging helper, "never call new Date() for now" style rules, copy rules.>

## 3. Tokens
| Utility / name | Variable | Use for |
<Every colour, radius, shadow, type size, weight, spacing grid and page padding, motion curve/duration. Mark which defaults were removed. Rules: the one accent and where it may appear, which colours are data-only, which properties may animate, how reduced motion is handled.>

## 4. Shared components
| Component | Main props | Example |
<Grouped: primitives, data-viz, domain, shell/overlays (backend: packages, middleware, clients). Where usage examples live (e.g. JSDoc @example). The page/route wrapper every page must use and its props. Store hooks and global actions. Global keyboard shortcuts pages must not rebind.>

## 5. The data model
| Entity | Where | Notes |
<One import entry point. Counts that must reconcile. Formatter functions every page must use.>

## 6. Known gaps
<Unowned routes, stubs, static parts, missing categories from reading the project, build-dir isolation gaps, accessibility or palette caveats, deliberate rule breaks and why.>
```

Add a `## 7. <Rule set>` section only for a settled cross-cutting rule the others must follow (for example "every colour on a chart has one job" or "the same number is drawn the same way everywhere").

## 3. Check it

1. For every path in the doc: `ls` it. For every command: confirm the script exists in the manifest. For every component and prop: grep it. Fix or remove anything that does not exist.
2. Every `[foundation]` folder in the tree is in the ownership rule's shared list, and vice versa.
3. Run each check command once (data check, typecheck, lint; not a dev server). Write the data check's pass count into section 1. Record any that fail or were not run as "unverified" in the report.
4. For each assigned port, `lsof -i :<port>`; if one is taken, pick another and update the doc.
5. Read the doc as a page agent starting cold: could you run your server, find a component, pick a colour and import the data without opening another file? If not, add the missing line.

## 4. Report

Tell the user: the path written, created or refreshed, the project root used, each agent with its ports and dirs, gaps for them to fix, anything unverified, and the opener to start every page agent's prompt with (drop the brief and refs clauses if there are none):

> Read `<brief path>` completely, every reference image in `<refs path>`, and `FOUNDATION.md`. Use the foundation's tokens, components and data; you may add new files and add exports, never rewrite shared files. Follow the brief's process section. Run your own dev server on your assigned port and build dir. Commit only your own paths. Build, lint and checks must pass before you report. Do not deploy, push or post.
