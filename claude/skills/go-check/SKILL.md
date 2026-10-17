---
name: go-check
description: 'Format, vet, build, test and lint Go code in one pass. Use after editing Go files, before calling Go work done, or when the user says "go-check".'
argument-hint: "[module-dir]"
---

# Go check

1. Find the project's own check command first: a `Makefile`, `Taskfile.yml`, `justfile` or CI workflow target that runs lint/test. If one exists, run it and skip to step 4.
2. Otherwise run these in order from the repo root (or the module root if `$ARGUMENTS` names one). On the first failure, fix it and re-run that step before moving on:

   ```bash
   gofmt -l .
   go vet ./...
   go build ./...
   go test -race ./...
   golangci-lint run
   ```

   If `gofmt -l .` lists files, run `goimports -w` (or `gofmt -w`) on them and re-check.
3. Sweep the Go code you touched: rename unused params to `_` when the signature must stay, inline single-use variables, and delete any binaries `go build` left behind.
4. End with a one-line pass/fail for each step you ran.
