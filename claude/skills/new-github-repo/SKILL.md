---
name: new-github-repo
description: 'Create a GitHub repo for the current folder: private by default, branches auto-deleted after merge, and the default branch protected. Use when the user says "create a GitHub repo", "make a repo", "new repo", "put this on GitHub", or invokes this skill by name.'
argument-hint: "[repo-name]"
---

# New GitHub Repo

Run every step from the project folder. Stop and tell the user on any unexpected error; never retry a failing command blindly.

## 1. Preflight

1. Run `gh auth status`. If not logged in, stop and tell the user to run `gh auth login`.
2. Get the login: `gh api user --jq .login`.
3. Get the folder name: `basename "$PWD"`. If it has spaces or characters other than letters, digits, `-`, `_`, `.`, turn it into kebab-case for the suggestion.

## 2. Ask

Ask both questions in ONE `AskUserQuestion` call:

- **Repo name.** Options: `$ARGUMENTS` if given, otherwise the folder name, labelled "(Recommended)"; and "Type a different name (org/name allowed)".
- **Visibility.** Options: "Private (Recommended)", "Public".

If the name contains `/`, OWNER is the part before it and NAME the part after. Otherwise OWNER is the login from step 1.

Then run `gh repo view OWNER/NAME`. If it succeeds, the repo already exists: stop and ask the user what to do.

## 3. Local git

1. If `git rev-parse --git-dir` fails, run `git init -b main`.
2. If `git remote get-url origin` succeeds, ask the user whether to replace it. On no, stop. Never overwrite it silently.

## 4. Create

Build URL from `gh config get git_protocol`: `ssh` gives `git@github.com:OWNER/NAME.git`, anything else gives `https://github.com/OWNER/NAME.git`.

```bash
gh repo create OWNER/NAME --private   # or --public
git remote add origin URL             # or: git remote set-url origin URL, if the user approved replacing it
```

Do not pass `--source` or `--push`; pushing is handled in step 6.

## 5. Auto-delete merged branches

```bash
gh repo edit OWNER/NAME --delete-branch-on-merge
gh api repos/OWNER/NAME --jq .delete_branch_on_merge
```

The second command must print `true`.

## 6. Make sure the default branch exists on GitHub

Protection blocks direct pushes, so the default branch must reach GitHub first. Set BRANCH with `git branch --show-current`. If it is empty (detached HEAD), stop and tell the user. If it is not `main`, warn that the first branch pushed becomes the GitHub default branch.

- **Local commits exist** (`git rev-parse HEAD` succeeds): ask "Push `BRANCH` now? After protection, changes go through pull requests." On yes, run `git push -u origin BRANCH`. On no, skip step 7 and tell the user to run it after the first push.
- **No commits:** show `git status --short`. If it is empty, skip the commit and step 7, and say so. Otherwise ask whether to make a first commit of those files. Point out anything that looks secret (`.env`, keys, tokens, credentials) and leave it out. On yes, run `git add <approved paths>`, `git commit -m "Initial commit"`, `git push -u origin BRANCH`. On no, skip step 7 and tell the user to run it after the first push.

Commit messages follow the user's global rules: no AI attribution lines.

## 7. Protect the default branch

Always try this; do not ask first.

```bash
gh api -X POST repos/OWNER/NAME/rulesets --input - <<'EOF'
{
  "name": "Protect default branch",
  "target": "branch",
  "enforcement": "active",
  "conditions": {"ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}},
  "rules": [
    {"type": "deletion"},
    {"type": "non_fast_forward"},
    {"type": "pull_request", "parameters": {
      "required_approving_review_count": 0,
      "dismiss_stale_reviews_on_push": false,
      "require_code_owner_review": false,
      "require_last_push_approval": false,
      "required_review_thread_resolution": false
    }}
  ]
}
EOF
gh api repos/OWNER/NAME/rulesets --jq '.[].name'
```

The second command must list "Protect default branch". This blocks deleting the branch, force pushes, and direct pushes. Changes go through a pull request; 0 approvals means a solo owner can merge their own PRs.

**If it fails with HTTP 403 mentioning an upgrade** (GitHub Pro for personal repos, GitHub Team for orgs): free plans cannot create rulesets or branch protection on private repos, not even switched off. Do not retry, do not change visibility, and do not ask. Record "protection not created: plan does not allow it on private repos" for the report and continue.

## 8. Report

List: repo URL, visibility, auto-delete on (yes/no), protection on (yes/no, and why not), and what was pushed (or that nothing was).
