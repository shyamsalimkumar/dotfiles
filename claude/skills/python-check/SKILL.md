---
name: python-check
description: 'Format, lint, type-check and test Python code in one pass. Use after editing Python files, before calling Python work done, or when the user says "python-check".'
---

# Python check

1. Find the project's own check command first: `pyproject.toml` scripts or tool config, a `Makefile`, `justfile`, `noxfile.py`, `tox.ini`, a pre-commit config or a CI workflow. If one exists, run it and skip to step 3.
2. Otherwise use the tools the project configures (look in `pyproject.toml`, `setup.cfg`, `.flake8`), run through its runner (`uv run`, `poetry run`, or the active venv). On the first failure, fix it and re-run that step:
   - Format: `ruff format`, or `black` if that's what's configured
   - Lint: `ruff check`, or `flake8`/`pylint` if configured
   - Types: `mypy` (or `pyright`) only if the project configures it
   - Tests: `pytest`
3. Sweep the code you touched: remove unused imports and variables, and delete caches or build output you created (`dist/`, `build/`, stray `.pyc`).
4. End with a one-line pass/fail for each step you ran.
