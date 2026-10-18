# shellcheck shell=bash
# Sourced by rebuild.sh and rebuild-linux.sh before they build.
# Builds normally come from the latest master. If this checkout is on another
# branch, or its master is behind origin/master, ask whether to build what's
# checked out or switch to the latest master first.

pick_branch() {
  local repo branch behind choice
  repo="$(git -C "$1" rev-parse --show-toplevel)"
  branch="$(git -C "$repo" branch --show-current)"

  if ! git -C "$repo" fetch -q origin master; then
    echo -e "${YELLOW}Couldn't fetch origin/master - building ${branch:-the current checkout} as is${NC}"
    return
  fi

  behind="$(git -C "$repo" rev-list --count master..origin/master)"
  [[ "$branch" == "master" && "$behind" == "0" ]] && return

  echo -e "${YELLOW}This checkout is on '${branch:-a detached HEAD}'. Local master is ${behind} commit(s) behind origin/master.${NC}"
  read -rp "Build the latest master or the current checkout? [M/c]: " choice
  [[ "$choice" =~ ^[Cc]$ ]] && return

  if [[ -n "$(git -C "$repo" status --porcelain)" ]]; then
    echo "Uncommitted changes in $repo - commit or stash them first, or choose 'c'." >&2
    exit 1
  fi
  git -C "$repo" switch -q master
  if ! git -C "$repo" merge -q --ff-only origin/master; then
    echo "Local master has commits that aren't on origin/master - sort that out first." >&2
    exit 1
  fi
  echo -e "${GREEN}Switched to the latest master ($(git -C "$repo" log -1 --format=%h))${NC}"
}
