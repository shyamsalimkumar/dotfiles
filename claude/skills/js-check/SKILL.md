---
name: js-check
description: 'Format, lint, type-check and test JavaScript or TypeScript code in one pass. Use after editing .js/.ts/.jsx/.tsx files, before calling JS/TS work done, or when the user says "js-check".'
---

# JavaScript / TypeScript check

1. Use the project's package manager, picked by lockfile: `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lock`/`bun.lockb` → bun, otherwise npm.
2. Find the project's own scripts in `package.json` (`check`, `lint`, `typecheck`, `test`, `format`) and run those. On the first failure, fix it and re-run that script.
3. For any step with no script, fall back to the configured tool through the package manager (`npx`/`pnpm exec`):
   - Format: `prettier --check` (or `biome format`) if configured
   - Lint: `eslint .` (or `biome lint`) if configured
   - Types: `tsc --noEmit` when there's a `tsconfig.json`
   - Tests: the test runner in `devDependencies` (vitest, jest, node --test)
4. Sweep the code you touched: remove unused imports and variables, and delete build output you created (`dist/`, `.next/`, coverage).
5. End with a one-line pass/fail for each step you ran.
