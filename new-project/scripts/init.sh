#!/usr/bin/env bash
#
# init.sh — deterministic half of the new-project ritual.
# Run from inside an empty project folder. The folder name becomes the repo name.
#
# Usage: init.sh [--visibility private|public]

set -euo pipefail

VISIBILITY="private"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --visibility)
      VISIBILITY="${2:-}"
      shift 2
      ;;
    --public)
      VISIBILITY="public"
      shift
      ;;
    *)
      echo "init.sh: unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ "$VISIBILITY" != "private" && "$VISIBILITY" != "public" ]]; then
  echo "init.sh: --visibility must be 'private' or 'public'" >&2
  exit 2
fi

NAME="$(basename "$PWD")"

# ---- guards ------------------------------------------------------------------

if [[ ! "$NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "init.sh: '$NAME' is not a valid GitHub repo name. Rename the folder." >&2
  exit 1
fi

if [[ -d .git ]]; then
  echo "init.sh: this directory is already a git repo. Refusing to touch it." >&2
  exit 1
fi

# This script commits everything in the current directory with `git add -A`
# and pushes it to a brand-new repo. If the folder isn't actually empty,
# that means publishing whatever was already sitting there — refuse instead.
shopt -s dotglob nullglob
entries=(*)
shopt -u dotglob nullglob
if [[ ${#entries[@]} -gt 0 ]]; then
  echo "init.sh: this directory is not empty. Refusing to run here — it would" >&2
  echo "         commit and push everything in it, including files unrelated" >&2
  echo "         to this project. Run from an empty folder instead." >&2
  exit 1
fi

for cmd in git gh; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "init.sh: '$cmd' not found on PATH." >&2; exit 1; }
done

if ! gh auth status >/dev/null 2>&1; then
  echo "init.sh: gh is not authenticated. Run 'gh auth login' first." >&2
  exit 1
fi

if gh repo view "$NAME" >/dev/null 2>&1; then
  echo "init.sh: a GitHub repo named '$NAME' already exists on your account." >&2
  exit 1
fi

# ---- foundation --------------------------------------------------------------

echo "==> git init ($NAME)"
git init -b main >/dev/null

echo "==> .gitignore"
cat > .gitignore <<'EOF'
node_modules/
dist/
build/
.next/
coverage/
*.log
.env
.env.*
!.env.example
.DS_Store
EOF

echo "==> README stub"
printf '# %s\n' "$NAME" > README.md

echo "==> first commit"
git add -A
git commit -m "chore: initial commit" >/dev/null

echo "==> creating GitHub repo ($VISIBILITY) and pushing"
gh repo create "$NAME" "--$VISIBILITY" --source=. --remote=origin --push >/dev/null

URL="$(gh repo view --json url --jq .url)"
echo
echo "Connected: $URL"
echo "Branch main is tracking origin/main. Foundation done — stack scaffold is next."
