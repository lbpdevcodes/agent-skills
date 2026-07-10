# agent-skills

Portable agent skills + coding standards, packaged for OpenAI Codex (CLI and
IDE extension), which supports the same `SKILL.md` agent-skills format as
Claude Code.

## Contents

| Path | What it is |
|---|---|
| `skills/sandi-metz-design/` | OO design the Sandi Metz way (POODR, 99 Bottles, the Metz Rules) |
| `skills/idiomatic-ruby-and-rails/` | Ruby/Rails conventions and idioms |
| `skills/clean-code-and-refactoring/` | Changeability heuristics and a code-smells catalog |
| `skills/prove-it-works/` | Failure-first, end-to-end proof that a change actually works |
| `skills/tdd/` | Disciplined red-green-refactor loop with an observed-failure gate (ported from Test Double's MIT-licensed [han](https://github.com/testdouble/han) plugin — see `skills/tdd/LICENSE`) |
| `AGENTS.md` | Global coding standards (TDD-first, testing rules, definition of done) |
| `install.sh` | Symlinks everything into place for Codex |

## Install (work machine)

```sh
git clone git@github.com:pandorocks/agent-skills.git
cd agent-skills
./install.sh
```

The script symlinks:

- each `skills/<name>` → `~/.agents/skills/<name>` (Codex's personal skills
  directory — discovered by both the CLI and the IDE extension)
- `AGENTS.md` → `~/.codex/AGENTS.md` (Codex's global instructions), only if
  you don't already have one; an existing file is never overwritten — merge
  by hand instead.

Then run `/skills` in Codex (or type `$` in the prompt) to confirm all five
skills are listed. Skills also trigger implicitly when a task matches their
description.

## Updating

Because everything is symlinked, updates are just:

```sh
git pull
```

Re-run `./install.sh` only if new skills were added (it's idempotent).

## Using with Claude Code too

The `skills/` directories are standard Claude Code skills. To make this repo
the single source of truth on a machine running Claude Code, symlink them into
`~/.claude/skills/` the same way.
