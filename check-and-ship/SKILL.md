---
name: check-and-ship
description: Ship the current branch straight into main — decide whether a version bump is warranted (patch/minor only, reasoned from the branch's changes, never asks which number), rebase onto main if it's moved since branching, then fast-forward-push directly to origin. Extends bump-push-main to the multi-branch/multi-agent case: several agents each on their own branch or worktree, each shipping into a shared main independently. Use when a branch's work is ready to land on main right now, no PR.
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/check-and-ship.sh *) Bash(git *) Bash(npm *)
---

# Check and ship

**What it does:** the deterministic half of "ship this branch": optionally
bumps `package.json`'s version (patch or minor only — never major, since no
project of mine has left the `0.x.x` phase), rebases onto the base branch if
it's moved since this branch started, and fast-forward-pushes straight to
`origin/main` (or `origin/master`). No PR, no merge commit.

**Assumes:** run from a git repo with an `origin` remote, on a branch other
than the base branch, with a clean working tree (commit or stash first —
this only ships committed history, it does not sweep up stragglers the way
`bump-push-main` does).

**Side effects:** may create one `chore: bump to X.Y.Z` commit, may rewrite
this branch's history via rebase, and pushes straight to `origin/main` with
no confirmation step beyond what's below — the version-bump decision and the
rebase are the only judgment calls, everything else is unconditional once
`ship` runs. Treat invoking `ship` itself as the approval gate: don't run it
until the branch is actually meant to land now.

## Step 1 — Guardrails (read-only)

Run:

```bash
${CLAUDE_SKILL_DIR}/scripts/check-and-ship.sh status
```

This reports branch, clean/dirty, ahead/behind counts against the base
branch, and whether this repo is marked as not managing versions. If dirty,
stop and get the tree clean first (commit or ask me) — do not guess what to
sweep in. If already on the base branch, stop — there's nothing to ship.

## Step 2 — Decide on a version bump

Skip this step entirely if `status` reported the repo as opted out of
version bumps, or if there's no `package.json` — go straight to Step 3 with
no `--bump` flag.

Otherwise, look at what this branch actually adds — `git log
origin/main..HEAD` and `git diff origin/main...HEAD` (excluding
`package.json`/lock files) — and use ordinary semver judgment:

- Not every branch needs a bump. Pure docs/config/internal-only changes can
  skip it — use judgment, same as `bump-push-main`.
- A user-visible fix → `patch`. A new capability → `minor`.
- Never `minor` vs `major` in the sense of asking me which number — decide
  the level yourself. You do not need my sign-off on the exact version
  string, only on the fact that `ship` is running at all (Step 1's gate
  covers that).
- Never pass `major`. The script refuses it outright regardless.

If I tell you in conversation that a given project doesn't manage versions,
run `${CLAUDE_SKILL_DIR}/scripts/check-and-ship.sh no-version` once — this
persists per-repo (keyed by the `origin` remote URL) so future runs in that
project skip the bump question entirely without being told again.

## Step 3 — Ship

```bash
${CLAUDE_SKILL_DIR}/scripts/check-and-ship.sh ship [--bump patch|minor]
```

This fetches, bumps if asked, rebases onto the base branch if it's moved,
and pushes to `origin/<base>`. If the rebase hits a conflict, the script
aborts it and leaves the branch exactly as it was — resolve manually and
re-run; do not attempt to auto-resolve conflicts yourself either.

## Step 4 — Hand back

Report the final line the script prints (`Shipped <branch> ->
origin/<base> (<sha>)`) and the new version if one was bumped. Note that any
other local checkout of this repo (e.g. someone's own working copy) won't
see the change until they pull — this skill never touches a checkout other
than the one it's run from.
