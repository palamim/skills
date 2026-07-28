---
name: new-project
description: Scaffold a new project my way — git init, .gitignore, GitHub repo named after the folder, first push, then a smallest-thing-that-runs and a rough 0.1.0. Use when starting a brand new project from an empty folder.
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/init.sh *) Bash(git *) Bash(gh *) Bash(npm *) Bash(npx *)
---

# New project

**What it does:** bootstraps a brand-new project — `git init`, `.gitignore`, first commit, a `gh repo create` under your account, and a first push — then walks through scaffolding a minimal working slice up to a rough 0.1.0.
**Assumes:** you run it from an *empty* directory whose name you're fine with becoming the GitHub repo name, and that `git` and `gh` are installed with `gh` already authenticated (`gh auth login`).
**Side effects:** creates and pushes to a new GitHub repository during step 2, before any code exists — `init.sh` refuses to run in a non-empty directory so it never commits or publishes files unrelated to the new project.

You are setting up a brand new project in the current directory. The directory
name is the project name and the GitHub repo name — do not rename anything.

## Step 1 — Ask before doing anything

If `$ARGUMENTS` is empty or too vague to build from, STOP and ask me:

1. What am I building? One sentence is enough.
2. Which stack? (plain Node/TypeScript, Next.js, CLI, or something else)
3. Public or private repo? Default to private.

Do not guess and do not proceed until I have answered. If `$ARGUMENTS` already
answers question 1, still confirm the stack and visibility before running
anything.

## Step 2 — Lay the foundation

Run the bundled script. It is deterministic and does the boring half:
git init, .gitignore, README stub, first commit, `gh repo create` named after
the folder, remote wired to origin, first push. It refuses to run unless the
current directory is empty and not already a git repo.

```bash
${CLAUDE_SKILL_DIR}/scripts/init.sh --visibility <private|public>
```

If the script exits non-zero, show me the error and stop. Do not try to
work around it by running the steps by hand.

## Step 3 — Scaffold the stack

Now install the stack I chose, in this same directory:

- Plain Node/TypeScript: `npm init -y`, then TypeScript + tsx, a `tsconfig.json`,
  and a `src/` directory.
- Next.js: `npx create-next-app@latest . --typescript` — note the `.`, it must
  scaffold into the existing directory, not a subdirectory.
- Anything else: ask me for the command if you are not sure.

Do not add linters, formatters, CI, Docker, test frameworks, or any dependency
I did not ask for. A dependency I have to remove later is worse than one I add
later.

## Step 4 — Smallest thing that runs

Build the smallest possible version of what I described that actually executes,
and prove it by running it. Not a hello world — the smallest real slice of the
idea. One function, one route, one command, whatever the thin end of it is.

Show me the output of the run. If it does not run, fix it before continuing.

## Step 5 — Rough 0.1.0

Extend that slice to a rough 0.1.0: the thing does its one job end to end, badly
is fine, incomplete is fine. Stop the moment it works. Do not polish, do not
generalize, do not add configuration for cases I have not hit yet.

Set `version` to `0.1.0` in package.json if there is one.

## Step 6 — README from reality

Rewrite README.md describing what exists right now — what it does, how to run
it. No roadmap, no planned features, no badges. If a section would describe
something not yet built, leave it out.

## Step 7 — Hand back

Show me `git status` and the full diff since the initial commit, propose a
commit message, and WAIT. Do not commit and do not push until I approve.
The foundation is mine to check before it goes anywhere.
