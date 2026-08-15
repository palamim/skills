# skills

Claude Code skills, shared as-is. Each one lives in its own directory with a
`SKILL.md` (the instructions Claude follows) and, where needed, a `scripts/`
folder holding the deterministic parts.

The pattern across all of them: judgment-requiring steps (asking questions,
deciding what to build) stay in `SKILL.md` as prose for Claude to reason
through; anything mechanical, order-sensitive, or destructive (repo creation,
file scaffolding, pushes) is pushed into a `scripts/` script that fails loudly
and refuses to run under ambiguous conditions instead of trying to recover.
Every skill that touches something irreversible stops and waits for your
approval before it does.

## new-project

Turns an empty folder into a running, pushed, versioned first slice of a
project — in one command.

`git init`, `.gitignore`, a GitHub repo named after the folder, first push,
stack scaffolding (plain TypeScript, Next.js, or whatever you name), the
smallest real version of the idea that actually runs, a rough `0.1.0`, and a
README that describes only what exists — then it hands control back to you
with a diff to review before anything gets committed.

![new-project scaffolding a small app end to end: an empty folder becomes a running project, a pushed GitHub repo, and a README, entirely from the terminal](new-project/demo.gif)

*From an empty folder to a working, pushed project: a name-prompt app that
writes a PNG greeting, built and run from the VS Code terminal, ending on the
pushed repo on GitHub.*

```bash
cp -r new-project ~/.claude/skills/
```

Then, from an empty directory:

```
/new-project a CLI that converts CSV to JSON
```

It will ask what you're building, which stack, and public or private —
answer those, and it does the rest. See
[`new-project/SKILL.md`](new-project/SKILL.md) for exactly what it does and
what it assumes (short version: `git` and `gh` installed and authenticated,
run from an empty directory).

## Install

Copy any skill's directory into your `~/.claude/skills/` folder — Claude Code
picks up skills from there automatically:

```bash
cp -r new-project ~/.claude/skills/
```

If you cloned this repo to hack on skills or keep them in sync with edits
here, symlink them in instead:

```bash
scripts/link-skills.sh
```

This links every skill in the repo into `~/.claude/skills/<name>`, skipping
any name that already exists there as a real (non-symlink) directory.

## Other skills

These two exist mainly to maintain this repo, but are useful patterns for any
skill collection of your own.

### create-skill

Scaffolds a new skill in this repo — `SKILL.md`, `scripts/` if needed, a
README entry — then symlinks it into `~/.claude/skills/` via
`scripts/link-skills.sh`. See
[`create-skill/SKILL.md`](create-skill/SKILL.md).

### bump-push-main

For any npm project: proposes a version bump for `package.json`
(patch/minor/major, reasoned from the session's changes), asks you to
confirm or override it — the only question it asks — then runs `npm install`
to sync the lockfile, stages everything uncommitted, commits, and pushes
straight to `main`. See
[`bump-push-main/SKILL.md`](bump-push-main/SKILL.md).

### dev-preview

For any npm/pnpm/yarn project: starts its dev server detached in the
background on the first free port and reports back the `localhost` URL —
handy when several agents are each working in their own git worktree of the
same repo and you want to preview each one without juggling terminal windows
or port collisions. Also supports `status`, `stop`, and `restart`. See
[`dev-preview/SKILL.md`](dev-preview/SKILL.md).

### check-and-ship

Ships the current branch straight into `main`: decides whether a version
bump is warranted (patch/minor only, reasoned from the branch's changes,
never asks which number — and remembers per-repo if you say it doesn't
manage versions), rebases onto `main` if it's moved since branching, then
fast-forward-pushes directly to `origin`. Built for the case where several
agents are each shipping their own branch or worktree into a shared `main`
independently. See [`check-and-ship/SKILL.md`](check-and-ship/SKILL.md).

## License

[MIT](LICENSE)
