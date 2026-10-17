Run the Go checklist in one pass: format, vet, build, test, lint.

Run these in order from the repo root (or the module root if `$ARGUMENTS` names one). On the first failure, fix it and re-run that step before moving on:

```bash
gofmt -l .
go vet ./...
go build ./...
go test -race ./...
golangci-lint run
```

If `gofmt -l .` lists files, run `gofmt -w` (or `goimports -w`) on them and re-check.

Then sweep the Go code you touched: rename unused params to `_` when the signature must stay, and delete any binaries `go build` left behind.

End with a one-line pass/fail for each of the five steps.
