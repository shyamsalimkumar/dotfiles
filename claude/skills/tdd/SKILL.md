---
name: tdd
description: Test-driven development with red-green-refactor loop. Use when user wants to build features or fix bugs using TDD, mentions "red-green-refactor", wants integration tests, or asks for test-first development.
---
<!-- imported from: https://github.com/mattpocock/skills/blob/main/skills/engineering/tdd/SKILL.md -->

# Test-Driven Development

## Core Rules

Tests verify behavior through public interfaces, never implementation details. Code can change entirely; tests shouldn't.

- Good tests are integration-style: they exercise real code paths through public APIs, describe WHAT the system does (not HOW), and read like a specification — "user can checkout with valid cart". They survive internal refactors.
- Bad tests mock internal collaborators, test private methods, assert on call counts/order, or verify through external means (e.g. querying the database directly instead of using the interface). Warning sign: a test breaks after a refactor that did not change behavior.

If unsure whether a test is behavior-focused, read [tests.md](tests.md) for good/bad examples (TypeScript and Go). Before adding ANY mock, read [mocking.md](mocking.md) — mock only at system boundaries.

## Anti-Pattern: Horizontal Slices

DO NOT write all tests first, then all implementation. Bulk-written tests verify imagined behavior and the shape of things (data structures, signatures) rather than user-facing behavior — they pass when behavior breaks and fail when it's fine, and they commit you to test structure before you understand the implementation.

Correct approach: vertical slices (tracer bullets). One test → one implementation → repeat. Each test responds to what the previous cycle taught you.

```
WRONG (horizontal): RED: test1..test5  then  GREEN: impl1..impl5
RIGHT (vertical):   test1→impl1, test2→impl2, test3→impl3, ...
```

## Workflow

### 1. Plan

If the project has a domain glossary (e.g. CONTEXT.md) or ADRs (e.g. docs/adr/), align test names and interface vocabulary with them; if absent, skip this and follow the codebase's existing naming.

Before writing any code:

- [ ] Confirm with user what interface changes are needed
- [ ] Confirm with user which behaviors to test, in priority order
- [ ] Identify opportunities for deep modules (small interface, deep implementation)
- [ ] Design interfaces for testability (accept external dependencies as parameters)
- [ ] List the behaviors to test (not implementation steps)
- [ ] Get user approval on the plan

Ask: "What should the public interface look like? Which behaviors are most important to test?"

You can't test everything — confirm with the user which behaviors matter most. Focus on critical paths and complex logic, not every edge case.

### 2. Tracer Bullet

Write ONE test that confirms ONE behavior. RED: it fails. GREEN: write minimal code so it passes. This proves the path works end-to-end.

### 3. Incremental Loop

For each remaining behavior: write the next test (RED, fails) → minimal code to pass (GREEN).

Rules:

- One test at a time
- Only enough code to pass the current test
- Don't anticipate future tests
- Keep tests focused on observable behavior

### 4. Refactor

Never refactor while RED — get to GREEN first. Then:

- [ ] Extract duplication
- [ ] Deepen modules (move complexity behind simple interfaces)
- [ ] Apply SOLID principles where natural
- [ ] Consider what new code reveals about existing code
- [ ] Run tests after each refactor step

## Checklist Per Cycle

- [ ] Test describes behavior, not implementation
- [ ] Test uses public interface only
- [ ] Test would survive internal refactor
- [ ] Code is minimal for this test
- [ ] No speculative features added
