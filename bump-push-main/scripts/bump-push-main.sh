#!/usr/bin/env bash
#
# bump-push-main.sh — set package.json's version to an exact value, sync the
# lockfile, and push everything uncommitted straight to origin main. No
# confirmation gate: the caller (bump-push-main SKILL.md) already asked the
# user to confirm or override the version and wrote the commit message
# before invoking this.
#
# Usage: bump-push-main.sh --version <X.Y.Z> --message "<msg>"

set -euo pipefail

VERSION=""
MESSAGE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="${2:-}"
      shift 2
      ;;
    --message)
      MESSAGE="${2:-}"
      shift 2
      ;;
    *)
      echo "bump-push-main.sh: unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "bump-push-main.sh: --version must be a plain X.Y.Z semver string (no leading 'v'), got '$VERSION'" >&2
  exit 2
fi

if [[ -z "$MESSAGE" ]]; then
  echo "bump-push-main.sh: --message is required" >&2
  exit 2
fi

# ---- guards ------------------------------------------------------------------

if [[ ! -f package.json ]]; then
  echo "bump-push-main.sh: no package.json in $(pwd) — this skill only works in npm projects." >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "bump-push-main.sh: not inside a git repo." >&2
  exit 1
fi

BRANCH="$(git branch --show-current)"
if [[ "$BRANCH" != "main" ]]; then
  echo "bump-push-main.sh: currently on '$BRANCH', not 'main'. Refusing to push" >&2
  echo "                    some other branch's history into main. Switch to main first." >&2
  exit 1
fi

if [[ -z "$(git status --porcelain)" ]]; then
  echo "bump-push-main.sh: working tree is clean — nothing to bump for." >&2
  exit 1
fi

command -v npm >/dev/null 2>&1 || { echo "bump-push-main.sh: npm not found on PATH." >&2; exit 1; }

# ---- bump, sync, ship ---------------------------------------------------------

echo "==> npm version $VERSION"
NEW_VERSION="$(npm version "$VERSION" --no-git-tag-version)"

echo "==> npm install (sync lockfile)"
npm install >/dev/null

echo "==> git add -A"
git add -A

echo "==> git commit"
git commit -m "$MESSAGE" >/dev/null

echo "==> git push origin main"
git push origin main

echo
echo "Bumped to ${NEW_VERSION#v}, committed, and pushed to main."
