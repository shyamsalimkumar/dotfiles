Wait for a GitHub PR's checks to finish and report whether it's mergeable, instead of hand-writing a `sleep && gh pr checks` loop.

PR number: use `$ARGUMENTS` if given, otherwise resolve the current branch's PR with `gh pr view --json number -q .number`.

Poll on a backoff (30s, 30s, 60s, 60s, 120s, then every 120s) running:

```bash
gh pr checks <pr-number> --json name,state,bucket 2>&1
gh pr view <pr-number> --json mergeable,mergeStateStatus,statusCheckRollup
```

Stop polling once every check has a terminal state (not `PENDING`/`QUEUED`/`IN_PROGRESS`) or `mergeable` is no longer `UNKNOWN`. Then report a short summary: which checks passed/failed, and whether the PR is mergeable (`MERGEABLE`, `CONFLICTING`, or blocked by required reviews). Don't loop indefinitely — after ~15 minutes of polling, stop and report the current state as "still pending" rather than continuing forever.
