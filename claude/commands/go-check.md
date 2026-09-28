Run the full Go checklist from AGENTS.md in one pass: format, vet, build, test, lint.

Run these in order from the repo root (or module root if `$ARGUMENTS` names one), stopping to report and fix on the first failure before moving to the next step:

```bash
gofmt -l .
go vet ./...
go build ./...
go test -race ./...
golangci-lint run
```

If `gofmt -l .` prints any files, run `gofmt -w` on them and re-check before moving on. Report a short pass/fail summary for each of the five steps at the end.
