---
name: dev-preview
description: Start a project's dev server in the background on a free port and report the URL back — for previewing an agent's work (e.g. one of several concurrent agents each in its own git worktree) without occupying a terminal or colliding with another running dev server. Use when the human wants to check a change is live without running the dev command themselves.
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/dev-preview.sh *)
---

# Dev preview

**What it does:** starts the current project's dev server (`npm`/`pnpm`/`yarn
run dev`) detached in the background on the first free port from 3000 up (or
a port you specify), so it survives this session ending, and reports back the
`http://localhost:<port>` URL. Safe to run from several worktrees of the same
repo at once — each is tracked separately by its own absolute path, and a
second `start` from the same directory reuses the already-running server
instead of starting a duplicate.

**Assumes:** run from the root of an npm/pnpm/yarn project (a directory with
`package.json` containing a `"dev"` script). Only works if that dev server
honors the `PORT` environment variable to pick its port — true for Next.js,
Create React App, and most Node dev servers. If a project's dev script
ignores `PORT`, this can't relocate it off a busy port; `start` will still
launch it, but on whatever port it defaults to.

**Side effects:** starts a detached background process (`nohup` + `disown`)
that keeps running after this session ends, until stopped explicitly. Writes
nothing into the project itself — state (pid, port, log) lives under
`$TMPDIR/dev-preview/<hash-of-project-path>/`. Does not touch git.

## Usage

```bash
${CLAUDE_SKILL_DIR}/scripts/dev-preview.sh start [--port N]
${CLAUDE_SKILL_DIR}/scripts/dev-preview.sh status
${CLAUDE_SKILL_DIR}/scripts/dev-preview.sh stop
${CLAUDE_SKILL_DIR}/scripts/dev-preview.sh restart [--port N]
```

## Step 1 — Start it

Run `start` from the project root whose change you want to preview (e.g. the
git worktree you've been working in). Omit `--port` unless the human asked
for a specific one — the script scans upward from 3000 for the first free
port and prints which one it picked. If a server is already running for this
exact directory, it reports that existing URL instead of starting a second
one — do not treat that as an error.

## Step 2 — Report back

State the URL plainly, exactly as the script prints it (`Preview:
http://localhost:<port>`). Nothing else needs summarizing. Do not open a
browser or claim to have visually verified the change — the human is the one
who's going to look.

## Step 3 — Clean up when it's no longer needed

Run `stop` once the preview has served its purpose (end of session, or the
human says they're done looking). Stale servers from finished sessions are
the main way this leaves processes running in the background — don't leave
more of them behind than necessary.
