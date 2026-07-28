# skills

Claude Code skills I use myself, shared as-is. Each skill lives in its own
directory with a `SKILL.md` (the instructions Claude follows) and, where
needed, a `scripts/` folder with the code it runs.

## Install

Copy a skill's directory into your `~/.claude/skills/` folder:

```bash
cp -r new-project ~/.claude/skills/
```

Claude Code picks up skills from that folder automatically.

If you cloned this repo to hack on skills or keep them in sync with edits here,
symlink them in instead:

```bash
scripts/link-skills.sh
```

This links every skill in the repo into `~/.claude/skills/<name>`, skipping any
name that already exists there as a real (non-symlink) directory.

## Skills

### new-project

Scaffolds a brand-new project from an empty folder: `git init`, a GitHub repo
named after the folder, first push, then a minimal working slice and a rough
`0.1.0`. See [`new-project/SKILL.md`](new-project/SKILL.md) for what it does
and what it assumes before you run it.

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
