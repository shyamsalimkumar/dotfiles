# Agent Instructions

Global instructions for all AI coding assistants (Claude, Codex, OpenCode, etc.)

## Workflow Orchestration

### #1 Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately — don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### #2 Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### #3 Self-Improvement Loop
- After each session, update `tasks/issues.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project context

### #4 Verification Before Done
- Don't mark a task complete without proof it works
- Diff behavior between main and your changes when relevant
- Ask yourself "Would a staff engineer accept this?"
- Run tests, check logs, demonstrate correctness

### #5 Demand Elegance (Balanced)
- For non-trivial changes pause and ask "is there a more elegant way?"
- If a fix feels hacky, however fast, ask "now, implement the elegant solution"
- Skip this for simple, obvious fixes
- Challenge your own work before presenting to the engineer

### #6 Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Focus on logs, errors, failing tests — then resolve them
- Zero context switching required from the user
- Write failing CI tests without being told how

### #7 Task Management
1. Write plan to `tasks/todo.md` with checkable items
2. Check in before starting implementation
3. Mark items complete as you go
4. High-level summary at each step
5. Surface blockers as soon as identified
6. Capture learnings after corrections

## Git Worktrees
- Always create worktrees in one of two locations:
  - `./worktrees/<branch-name>` inside the project repo, OR
  - `~/worktrees/<project-name>-<branch-name>` in the home directory
- Prefer `./worktrees/` when the repo's `.gitignore` covers it; use `~/worktrees/` otherwise

## Core Principles
- **Simplicity First**: Make every change as simple as possible. Impact minimal code. Don't introduce unnecessary complexity.
- **No Laziness**: Don't cut corners. No temporary fixes. Senior developer standards apply.
- **Minimal Changes**: Must touch only what's necessary. Avoid introducing bugs.

## Development Workflow

**Prefer TDD approach when possible.** Use Red-Green-Refactor cycle for new features and bug fixes. Fall back to non-TDD only when TDD is impractical (exploratory work, prototypes).

### TDD Approach (Red-Green-Refactor) - Preferred

1. **Red**: Write a failing test
2. **Green**: Implement minimal code to make the test pass
3. **Refactor**: Clean up code (extract methods, rename variables, remove duplication)
4. **Lint**: Fix linting errors
5. **Build**: Fix compilation/build errors
6. **Format**: Format all modified files

### Non-TDD Approach (when TDD impractical)

1. **Implement**: Make the changes
2. **Lint**: Fix all linting errors
3. **Build**: Fix all compilation/build errors
4. **Test**: Fix all test failures
5. **Format**: Format all modified files (once, after everything passes)

### General Cleanup Rules

- Remove unused variables, parameters, methods, imports
- If variables are used only once, inline them unless it hurts readability
- Clean up generated files appropriately (don't manually edit code-generated files)
- After completing any task, verify: lint passes, builds succeed, tests pass, files formatted

### Language-Specific Notes

**Go:**
- Always format edited Go files with `gofmt` or `goimports`
- Run `golangci-lint` and fix all issues
- Run `go test` to ensure tests pass
- Run `go build` to verify compilation
- Making changes to `*_gen.go` files is pointless since they're generated - create new files instead

**Python:**
- Format with `black` or project's configured formatter
- Run `pylint` or `flake8`
- Run `mypy` for type checking if project uses it
- Run `pytest` to ensure tests pass

**JavaScript/TypeScript:**
- Format with `prettier` or project's configured formatter
- Run `eslint` and fix all issues
- Run `tsc` for TypeScript type checking
- Run `npm test` or `yarn test`

**Rust:**
- Format with `cargo fmt`
- Run `cargo clippy` and fix all warnings
- Run `cargo test`
- Run `cargo build` or `cargo check`

## Code Review Standards

Before submitting any code:
1. **Self-review**: Read through all changes as if reviewing someone else's PR
2. **Test coverage**: Ensure new code has appropriate test coverage
3. **Documentation**: Update relevant documentation and comments
4. **Breaking changes**: Call out any breaking changes explicitly
5. **Performance**: Consider performance implications of changes
6. **Security**: Review for common vulnerabilities (OWASP Top 10)

## Common Pitfalls to Avoid

- Don't add features beyond what was requested
- Don't refactor code that isn't related to the task
- Don't add error handling for scenarios that can't happen
- Don't create abstractions for single-use code
- Don't add backwards-compatibility hacks unless explicitly needed
- Don't use feature flags or configuration for things that should just be changed
- Don't add comments explaining what code does (code should be self-explanatory)
- Don't add docstrings, type annotations, or comments to code you didn't change

## When to Ask for Clarification

Ask questions when:
- Requirements are ambiguous or contradictory
- Multiple valid approaches exist and the choice affects architecture
- You need to make a decision that will be hard to change later
- The user's request might not solve their actual problem
- Security or data loss concerns exist

Don't ask when:
- The path forward is clear and conventional
- You can make a reasonable default choice
- The question is about minor implementation details
- The user has already provided enough context

---

This file is symlinked to `~/.claude/CLAUDE.md` (via `claude/CLAUDE.md` → `home/AGENTS.md`).

The nix-darwin setup also creates symlinks to `~/.codex/AGENTS.md` and `~/.config/opencode/AGENTS.md` for other AI coding assistants to read the same instructions for consistency.
