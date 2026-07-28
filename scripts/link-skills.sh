#!/usr/bin/env bash
#
# link-skills.sh — symlink every skill in this repo into ~/.claude/skills/,
# so edits here are live immediately without re-copying.
#
# Usage: scripts/link-skills.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="$HOME/.claude/skills"

mkdir -p "$TARGET_DIR"

for skill_path in "$REPO_DIR"/*/; do
  [[ -f "$skill_path/SKILL.md" ]] || continue
  name="$(basename "$skill_path")"
  link="$TARGET_DIR/$name"

  if [[ -L "$link" ]]; then
    echo "==> $name: already linked, updating"
    rm "$link"
  elif [[ -e "$link" ]]; then
    echo "==> $name: exists at $link and is not a symlink — skipping (remove it manually if you want to link instead)" >&2
    continue
  fi

  ln -s "${skill_path%/}" "$link"
  echo "==> $name -> $link"
done
