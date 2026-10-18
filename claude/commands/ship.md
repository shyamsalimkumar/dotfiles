Ship the current work: commit, open a PR, wait for checks, merge, and clean up. Typing `/ship` is the user's go-ahead to merge this PR; there is no second confirmation. `$ARGUMENTS` may name an existing PR number; `no-merge` stops after the checks.

1. **Commit.** On the default branch, first create a branch named after the change. Commit any pending changes. Push with `-u`.
2. **PR.** Reuse the branch's open PR if there is one (`gh pr view --json number`); otherwise open one against the default branch with the problem, root cause and how it was tested.
3. **Checks.** Wait the way `~/.claude/commands/pr-wait.md` says. A failed job whose annotation says the job was not started because of account payments or a spending limit is a **billing failure**, not a code failure: count it as skipped and say so in one line. Any other failure: stop and report it.
4. **Merge.** `gh pr merge <n> --merge --delete-branch`; when the repo disallows merge commits, use `--squash`. A PR that is not `MERGEABLE` stops here with the reason.
5. **Sync.** Bring the main checkout's default branch up to date (`git -C <main checkout> pull --ff-only`). Remove a worktree you made under `./worktrees/` for this branch; leave a desktop-app worktree (`.claude/worktrees/`) alone.
6. **Report** in three lines: PR link and merge state, skipped checks if any, and that the next feature is best started in a fresh session.
