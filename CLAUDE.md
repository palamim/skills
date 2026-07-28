# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A collection of Claude Code skills, shared as-is. Each skill is a self-contained directory with a `SKILL.md` (the instructions Claude follows when the skill runs) and, where needed, a `scripts/` folder with the code it executes. There is no build, lint, or test tooling — this is a documentation/prompt repo, not a software package.

## Repo structure

```
<skill-name>/
  SKILL.md          # instructions Claude follows; has YAML frontmatter (name, description, allowed-tools, etc.)
  scripts/           # deterministic shell/code the skill invokes — kept separate from the LLM-driven steps
```

Skills are installed by copying their directory into `~/.claude/skills/`:

```bash
cp -r <skill-name> ~/.claude/skills/
```

## Working on a skill

- `SKILL.md` frontmatter's `allowed-tools` whitelists exactly which shell commands the skill may invoke (e.g. `Bash(git *)`) — update it if a skill's instructions start requiring a new command.
- Prefer pushing deterministic, order-sensitive, or destructive logic into a `scripts/` shell script rather than describing it as prose steps in `SKILL.md`. `SKILL.md` should drive the judgment-requiring parts (asking the user questions, deciding what to build) and hand off to the script for the mechanical, guard-railed parts (repo creation, file scaffolding).
- Scripts that create/push to external systems (e.g. `gh repo create`) should fail loudly and refuse to run under ambiguous conditions (non-empty directory, existing remote repo, missing auth) rather than trying to recover or work around the condition.
- Match the existing tone in `SKILL.md` files: terse, imperative, written as direct instructions to Claude ("Do not guess and do not proceed until I have answered"), with explicit stop conditions and explicit "wait for approval" gates before irreversible actions (commits, pushes, repo creation).

## Adding a new skill

Follow the pattern of `new-project/`: a `SKILL.md` with frontmatter (`name`, `description`, `allowed-tools`, and `disable-model-invocation: true` if it should only run when explicitly invoked, not auto-triggered), numbered steps, and a `scripts/` script for the deterministic portion. Add a matching entry under `## Skills` in `README.md`.
