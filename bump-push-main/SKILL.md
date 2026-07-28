---
name: bump-push-main
description: Propose a version bump for package.json (patch/minor/major, reasoned from the session's changes), ask the user to confirm or override it — the only question this skill asks — then run npm install to sync the lockfile, stage everything uncommitted, commit, and push straight to main. Use when wrapping up a session of changes in an npm project and you want one command to bump, commit, and push.
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/bump-push-main.sh *) Bash(git *) Bash(npm *)
---

# Bump, push, main

**What it does:** bumps `package.json`'s version, runs `npm install` so the
lockfile reflects it, stages every uncommitted change in the working tree,
commits, and pushes directly to `origin main`.
**Assumes:** run from the root of an npm project (a directory with
`package.json`) that is a git repo currently on the `main` branch, with at
least one uncommitted change.
**Side effects:** this skill asks exactly one question (the version to bump
to) and otherwise does **not** pause for approval — it commits and pushes to
`main` in one shot, with no PR and no other confirmation step. Only invoke it
when you actually mean to ship everything currently sitting in the working
tree.

## Step 1 — Guardrails (read-only, before touching anything)

Confirm all of the following yourself before running the script — the script
also checks these and refuses on failure, but check first so you don't waste a
version bump on a doomed run:

- `package.json` exists in the current directory. If not, stop: this skill
  only applies to npm projects.
- The current directory is inside a git repo.
- The current branch is `main`. If not, stop and tell me to switch branches —
  do not check it out yourself.
- `git status --porcelain` is non-empty. If the tree is fully clean, stop and
  tell me there's nothing to bump for.

## Step 2 — Propose a version, ask exactly one question

Read the current version from `package.json`. Look at what actually changed
this session — `git diff`, `git status`, and your own memory of what was
built — and infer the bump using ordinary semver judgment:

- **patch** — bug fixes, small tweaks, no new capability.
- **minor** — new backwards-compatible functionality.
- **major** — breaking changes.

Then ask me a single question with your proposed version as the recommended
option, and a second option for me to supply a different version myself (I
may pick that one and type any version string). This is the only question
this skill asks — do not ask anything else, and do not add extra confirmation
steps around it.

## Step 3 — Run it

Once the version is settled (whichever I chose), run:

```bash
${CLAUDE_SKILL_DIR}/scripts/bump-push-main.sh --version <version> --message "<commit message>"
```

`<version>` is the plain semver string (e.g. `0.9.0`, no leading `v`) decided
in Step 2. Compose `<commit message>` yourself, summarizing what the session
actually did — not just "version bump". Keep it to one line to avoid
shell-quoting surprises.

The script sets `package.json` (and the lockfile's version field) to that
exact version via `npm version --no-git-tag-version`, runs `npm install` to
fully sync the lockfile, stages everything not yet staged or committed
(`git add -A`), commits with your message, and pushes straight to
`origin main`. It refuses immediately if any Step 1 guardrail fails, or if
`<version>` isn't a plain `X.Y.Z` semver string — it does not try to recover
or work around a failed check.

## Step 4 — Report

Show me the new version number, the commit hash, and confirm the push
succeeded.
