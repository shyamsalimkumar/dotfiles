# Logic Prototype

An interactive terminal app that lets the user drive a state model by hand. Right shape when the question is about business logic, state transitions, data shape, or API feel — "does this state machine handle X then Y?", "can this data model represent...?", anything where the user wants to press buttons and watch state change. If the question is "what should this look like?", wrong branch — use [UI.md](UI.md).

## Steps

### 1. State the question

Before writing code, write one paragraph — what state model, what question — in the prototype's README or a comment at the top of the file, so it can be checked later whether the user is watching or away.

### 2. Pick the language

Use the host project's language and existing tooling. Don't add a new package manager or runtime for the prototype. If the project has no obvious runtime (e.g. a docs repo), ask the user.

### 3. Isolate the logic in a portable pure module

Put the logic that answers the question behind a small pure interface, separate from the TUI, so it can be lifted into the real codebase later. Pick the shape that fits the question — not whichever is easiest to wire to a TUI:

- **Pure reducer** `(state, action) => state` — discrete events, state is a single value.
- **Explicit state machine** — when "which actions are even legal right now" is part of the question.
- **Small set of pure functions** over a plain data type — no implicit current state, just transformations.
- **Class or module with a clear method surface** — when the logic genuinely owns ongoing internal state.

Keep the module pure: no I/O, no terminal code, no `console.log` for control flow. The TUI imports the module and calls into it; nothing flows the other direction. When the question is answered, the module can move into real code; the TUI gets deleted.

### 4. Build the smallest TUI that exposes the state

On every tick, clear the screen (`console.clear()` / `print("\033[2J\033[H")` / equivalent) and re-render the whole frame — one stable view, not growing scrollback. Frame layout, in order:

1. **Current state**, pretty-printed and diff-friendly (one field per line, or formatted JSON). Bold field names and section headers, dim secondary info (timestamps, IDs, derived values). Native ANSI codes are fine — `\x1b[1m` bold, `\x1b[2m` dim, `\x1b[0m` reset. No styling library unless the project already has one.
2. **Keyboard shortcuts** at the bottom: `[a] add user  [d] delete user  [t] tick clock  [q] quit`. Bold the key, dim the description (or vice versa).

Loop:

1. Initialise a single in-memory state object; render the first frame on start.
2. Read one keystroke (or one line) at a time; dispatch to a handler that updates state.
3. Re-render the full frame after every action — replace, never append.
4. Repeat until quit.

The whole frame must fit on one screen.

### 5. Make it runnable in one command

Add a script to the project's task runner (`package.json` scripts, `Makefile`, `justfile`, `pyproject.toml`) so the user runs `pnpm run <prototype-name>` or equivalent — never a path they must remember. If there's no task runner, put the exact command at the top of the prototype's README.

### 6. Hand it over

Give the user the run command; they drive it themselves. Moments like "wait, that shouldn't be possible" are bugs in the idea — the whole point. If they want new actions, add them; prototypes evolve.

### 7. Capture the answer

The answer is the only thing worth keeping. If the user is around, ask what it taught them. If not, leave a `NOTES.md` next to the prototype so the answer can be filled in (by them or by you, if you watched the session) before the prototype is deleted.

## Anti-patterns

- **Don't add tests.** A prototype that needs tests is no longer a prototype.
- **Don't wire it to the real database.** In-memory store only, unless the question is specifically about persistence.
- **Don't generalise.** No "what if we wanted X later" — the prototype answers one question.
- **Don't blur logic and TUI.** If the reducer / state machine references `console.log`, prompts, or escape codes, it's no longer portable.
- **Don't ship the TUI shell to production.** Only the logic module behind it is worth keeping.
