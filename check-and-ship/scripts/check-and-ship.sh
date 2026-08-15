#!/usr/bin/env bash
#
# check-and-ship.sh — ship the current branch straight into main: optionally
# bump the project's version (patch/minor only, never major — no project of
# mine has left the 0.x.x phase), rebase onto the base branch if it's moved,
# then fast-forward-push directly to origin.
#
# Usage:
#   check-and-ship.sh ship [--bump patch|minor] [--base <branch>]
#   check-and-ship.sh no-version
#   check-and-ship.sh status [--base <branch>]

set -euo pipefail

STATE_DIR="$HOME/.claude/skill-state/check-and-ship"
STATE_FILE="$STATE_DIR/no-version-bump.txt"

COMMAND="${1:-}"
shift || true

BUMP=""
BASE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --bump)
      BUMP="${2:-}"
      shift 2
      ;;
    --base)
      BASE="${2:-}"
      shift 2
      ;;
    *)
      echo "check-and-ship.sh: unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ "$COMMAND" != "ship" && "$COMMAND" != "no-version" && "$COMMAND" != "status" ]]; then
  echo "check-and-ship.sh: usage: check-and-ship.sh {ship [--bump patch|minor] [--base <branch>]|no-version|status [--base <branch>]}" >&2
  exit 2
fi

if [[ -n "$BUMP" && "$BUMP" != "patch" && "$BUMP" != "minor" ]]; then
  echo "check-and-ship.sh: --bump must be 'patch' or 'minor' — major bumps are refused on purpose (no project has left 0.x.x)." >&2
  exit 2
fi

# ---- guards ------------------------------------------------------------------

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "check-and-ship.sh: not inside a git repo." >&2
  exit 1
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  echo "check-and-ship.sh: no 'origin' remote — nowhere to ship to." >&2
  exit 1
fi

BRANCH="$(git branch --show-current)"
if [[ -z "$BRANCH" ]]; then
  echo "check-and-ship.sh: detached HEAD — checkout a branch first." >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
REPO_ID="$(git remote get-url origin 2>/dev/null || echo "$REPO_ROOT")"

mkdir -p "$STATE_DIR"
touch "$STATE_FILE"

is_opted_out() {
  grep -qxF "$REPO_ID" "$STATE_FILE" 2>/dev/null
}

detect_base() {
  if [[ -n "$BASE" ]]; then
    echo "$BASE"
    return
  fi
  if git show-ref --verify --quiet "refs/remotes/origin/main"; then
    echo "main"
  elif git show-ref --verify --quiet "refs/remotes/origin/master"; then
    echo "master"
  else
    echo "check-and-ship.sh: can't find origin/main or origin/master — pass --base <branch>." >&2
    exit 1
  fi
}

# ---- no-version ---------------------------------------------------------------

if [[ "$COMMAND" == "no-version" ]]; then
  if is_opted_out; then
    echo "already marked: $REPO_ID does not manage versions"
  else
    echo "$REPO_ID" >> "$STATE_FILE"
    echo "marked: $REPO_ID will be skipped for version bumps from now on"
  fi
  exit 0
fi

BASE_BRANCH="$(detect_base)"

if [[ "$BRANCH" == "$BASE_BRANCH" ]]; then
  echo "check-and-ship.sh: currently on '$BASE_BRANCH' — this ships a feature branch into it, nothing to do here." >&2
  exit 1
fi

echo "==> git fetch origin"
git fetch origin --quiet

# ---- status -------------------------------------------------------------------

if [[ "$COMMAND" == "status" ]]; then
  DIRTY="clean"
  [[ -n "$(git status --porcelain)" ]] && DIRTY="dirty"
  AHEAD_BEHIND="$(git rev-list --left-right --count "origin/$BASE_BRANCH...HEAD")"
  BEHIND="$(echo "$AHEAD_BEHIND" | cut -f1)"
  AHEAD="$(echo "$AHEAD_BEHIND" | cut -f2)"
  OPT="not opted out"
  is_opted_out && OPT="opted out of version bumps"
  echo "branch:        $BRANCH ($DIRTY)"
  echo "base:          $BASE_BRANCH"
  echo "ahead/behind:  $AHEAD ahead, $BEHIND behind origin/$BASE_BRANCH"
  echo "versioning:    $OPT"
  exit 0
fi

# ---- ship -----------------------------------------------------------------

if [[ -n "$(git status --porcelain)" ]]; then
  echo "check-and-ship.sh: working tree is dirty. Commit or stash your changes first — ship only pushes committed history." >&2
  exit 1
fi

if [[ -n "$BUMP" ]]; then
  if [[ ! -f package.json ]]; then
    echo "check-and-ship.sh: --bump was given but there's no package.json in $REPO_ROOT." >&2
    exit 1
  fi
  if is_opted_out; then
    echo "check-and-ship.sh: $REPO_ID is marked as not managing versions (run 'no-version' to undo) — omit --bump." >&2
    exit 1
  fi
  command -v npm >/dev/null 2>&1 || { echo "check-and-ship.sh: npm not found on PATH." >&2; exit 1; }

  echo "==> npm version $BUMP"
  NEW_VERSION="$(npm version "$BUMP" --no-git-tag-version)"

  echo "==> npm install (sync lockfile)"
  npm install >/dev/null

  echo "==> git commit (version bump)"
  git add -A
  git commit -m "chore: bump to ${NEW_VERSION#v}" >/dev/null
fi

MERGE_BASE="$(git merge-base "origin/$BASE_BRANCH" HEAD)"
REMOTE_TIP="$(git rev-parse "origin/$BASE_BRANCH")"

if [[ "$MERGE_BASE" != "$REMOTE_TIP" ]]; then
  echo "==> origin/$BASE_BRANCH has moved — rebasing"
  if ! git rebase "origin/$BASE_BRANCH"; then
    git rebase --abort
    echo "check-and-ship.sh: rebase onto origin/$BASE_BRANCH hit a conflict. Aborted and left your" >&2
    echo "                    branch as it was — resolve manually (git rebase origin/$BASE_BRANCH)" >&2
    echo "                    and re-run ship afterward." >&2
    exit 1
  fi
else
  echo "==> origin/$BASE_BRANCH unchanged since branching — no rebase needed"
fi

echo "==> git push origin HEAD:$BASE_BRANCH"
git push origin "HEAD:$BASE_BRANCH"

echo
echo "Shipped $BRANCH -> origin/$BASE_BRANCH ($(git rev-parse --short HEAD))"

if git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null 2>&1; then
  echo "==> git push origin --delete $BRANCH (shipped, no PR ever pointed at it — no more use)"
  git push origin --delete "$BRANCH"
fi
