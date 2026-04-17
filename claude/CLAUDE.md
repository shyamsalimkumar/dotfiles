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

## Core Principles
- **Simplicity First**: Make every change as simple as possible. Impact minimal code. Don't introduce unnecessary complexity.
- **No Laziness**: Don't cut corners. No temporary fixes. Senior developer standards apply.
- **Minimal Changes**: Must touch only what's necessary. Avoid introducing bugs.

## Go
- Always format edited files. Especially Go files
- Remove unused Go variables, parameters and methods that you'd generated at the end. Also if variables are unneeded and can be directly used instead prefer that when the value isn't reused.
- If you're generating builds be sure to cleanup after.
- Always cleanup after the operation is over. Cleanup any unused variables, methods, params (convert to _ unless they can be removed completely), files and similar resources.
- Making changes to crud_gen.go is pointless since it's a generated file. Create a new struct instead if you need to edit one in crud. You can place it in crud.go if you desire.
- Remove any unused variables, files, methods, etc once done. Clean up after yourself.
- After doing a task that involves editing Go files, format, test, golangci lint, and build the project.
