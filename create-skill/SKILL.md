---
name: create-skill
description: Scaffold a new Claude Code skill in this repo (SKILL.md, and scripts/ if needed), register it in README.md, then symlink it into ~/.claude/skills via scripts/link-skills.sh. Use when adding a new skill to this repository.
disable-model-invocation: true
allowed-tools: Bash(./scripts/link-skills.sh *) Bash(mkdir *) Bash(git *)
---

# Create skill

**What it does:** scaffolds a new skill directory in this repo, registers it in
`README.md`, and symlinks it into `~/.claude/skills/` so it's immediately
usable and live-editable.
**Assumes:** run from the root of this repo (`CLAUDE.md` documents the
conventions this follows).
**Side effects:** creates a new directory and files in this repo, appends an
entry to `README.md`, and creates a symlink under `~/.claude/skills/`.

## Step 1 — Ask before scaffolding

If not already answered, ask me:

1. Skill name (kebab-case — becomes the directory name and
   `~/.claude/skills/<name>`).
2. One-line description (goes in the frontmatter and the README entry).
3. Should this run only when explicitly invoked (`disable-model-invocation:
   true`), or can Claude auto-trigger it from context?
4. Does it need a `scripts/` folder for deterministic/destructive steps, or is
   it pure prose instructions?
5. What commands will it need to run? (used to fill `allowed-tools`)

Do not guess and do not scaffold until I've answered.

## Step 2 — Scaffold

Create `<name>/SKILL.md` with frontmatter (`name`, `description`,
`disable-model-invocation` if asked for, `allowed-tools`). Match the tone of
the existing skills: terse, imperative, numbered steps, explicit stop
conditions, and a "wait for approval" gate before anything irreversible
(commits, pushes, external side effects).

If a `scripts/` folder is needed, create it with a script that follows the
guard-rail style of `new-project/scripts/init.sh` — fail loudly and refuse to
run under ambiguous conditions rather than trying to recover silently.

## Step 3 — Register

Add a one-line entry under `## Skills` in `README.md`, matching the format of
the existing `new-project` entry.

## Step 4 — Link it

Run:

```bash
./scripts/link-skills.sh
```

Confirm the new skill shows up as a symlink at `~/.claude/skills/<name>`.

## Step 5 — Hand back

Show me `git status` and the diff, propose a commit message, and WAIT. Do not
commit or push until I approve.
