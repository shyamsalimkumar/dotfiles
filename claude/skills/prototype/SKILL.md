---
name: prototype
description: Build a throwaway prototype to flesh out a design before committing to it. Routes between two branches — a runnable terminal app for state/business-logic questions, or several radically different UI variations toggleable from one route. Use when the user wants to prototype, sanity-check a data model or state machine, mock up a UI, explore design options, or says "prototype this", "let me play with it", "try a few designs".
---
<!-- imported from: https://github.com/mattpocock/skills/blob/main/skills/engineering/prototype/SKILL.md -->

# Prototype

A prototype is throwaway code that answers a question. Identify the question first — from the prompt, the surrounding code, or by asking the user — then read exactly one branch file and follow it:

- **"Does this logic / state model feel right?"** → read [LOGIC.md](LOGIC.md): a tiny interactive terminal app that drives the state model by hand.
- **"What should this look like?"** → read [UI.md](UI.md): several radically different UI variants on one route, switchable via a `?variant=` URL param and a floating bottom bar.

Getting the branch wrong wastes the whole prototype. If the question is ambiguous and the user is unreachable, pick the branch matching the code the prototype is for: a backend module → LOGIC.md; a page or component → UI.md. State that assumption in a comment at the top of the prototype.

## Rules for both branches

1. **Throwaway, clearly marked.** Put the prototype next to the module or page it's for, but name it so a casual reader sees it's a prototype, not production. For throwaway UI routes, follow the project's existing routing convention — don't invent a new top-level structure.
2. **One command to run**, via the project's existing task runner (`pnpm <name>`, `python <path>`, `bun <path>`, etc.). The user must be able to start it without thinking.
3. **No persistence by default.** State lives in memory — persistence is what the prototype checks, not something it depends on. Only if the question is explicitly about a database, use a scratch DB or local file with a clear "PROTOTYPE — wipe me" name.
4. **Skip polish.** No tests, no abstractions, no error handling beyond what keeps it runnable.
5. **Surface the state.** Print or render the full relevant state after every action (logic) or on every variant switch (UI).
6. **Delete or absorb when done.** Delete the prototype or fold the validated decision into the real code — never leave it rotting in the repo.

## When done

The answer is the only thing worth keeping. Capture it, with the question it answered, somewhere durable: commit message, ADR, issue, or a `NOTES.md` next to the prototype. If the user is around, ask what it taught them; if not, leave the `NOTES.md` placeholder so the verdict can be filled in before the prototype is deleted.
