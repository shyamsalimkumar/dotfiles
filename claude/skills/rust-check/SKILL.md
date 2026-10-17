---
name: rust-check
description: 'Format, lint, build and test Rust code in one pass. Use after editing Rust files, before calling Rust work done, or when the user says "rust-check".'
---

# Rust check

1. Find the project's own check command first: a `Makefile`, `justfile`, `xtask` or CI workflow target. If one exists, run it and skip to step 3.
2. Otherwise run these in order from the workspace root. On the first failure, fix it and re-run that step:

   ```bash
   cargo fmt --all -- --check
   cargo clippy --all-targets -- -D warnings
   cargo test
   ```

   If `cargo fmt --check` fails, run `cargo fmt --all` and re-check.
3. Sweep the code you touched: remove unused imports and variables, prefix unused params with `_` when the signature must stay.
4. End with a one-line pass/fail for each step you ran.
