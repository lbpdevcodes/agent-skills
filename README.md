# agent-skills

Portable agent skills, coding standards, and Claude Code settings — one repo
that sets up Claude Code and OpenAI Codex (CLI and IDE extension) the same way
on every machine. Both tools read the same `SKILL.md` agent-skills format.

## Contents

| Path | What it is |
|---|---|
| `skills/sandi-metz-design/` | OO design the Sandi Metz way (POODR, 99 Bottles, the Metz Rules) |
| `skills/idiomatic-ruby-and-rails/` | Ruby/Rails conventions and idioms |
| `skills/clean-code-and-refactoring/` | Changeability heuristics and a code-smells catalog |
| `skills/prove-it-works/` | Failure-first, end-to-end proof that a change actually works |
| `skills/tdd/` | Disciplined red-green-refactor loop with an observed-failure gate (ported from Test Double's MIT-licensed [han](https://github.com/testdouble/han) plugin — see `skills/tdd/LICENSE`) |
| `AGENTS.md` | Global coding standards (TDD-first, testing rules, definition of done, communication) |
| `claude/settings.json` | Claude Code settings shared by every machine: the [han](https://github.com/testdouble/han) plugins and their marketplace, per-model effort, theme |
| `claude/settings.macos.json` | Extra Claude Code settings applied only on macOS (`swift-lsp` plugin) |
| `install-claude.sh` | Installs everything for Claude Code |
| `install.sh` | Symlinks skills and `AGENTS.md` into place for Codex |

## Install

```sh
git clone git@github.com:lbpdevcodes/agent-skills.git ~/software/agent-skills
cd ~/software/agent-skills
./install-claude.sh   # Claude Code
./install.sh          # Codex
```

### Claude Code — `install-claude.sh`

Requires `jq` and the `claude` CLI. The script:

- symlinks each `skills/<name>` → `~/.claude/skills/<name>`, except `tdd`,
  which the `han-coding` plugin provides to Claude Code
- symlinks `AGENTS.md` → `~/.claude/CLAUDE.md`, only if you don't already have
  one; an existing file is never overwritten — merge by hand instead
- merges `claude/settings.json` (and `claude/settings.macos.json` on macOS)
  into `~/.claude/settings.json`. The repo's values win for the keys it sets;
  everything else — hooks, permissions, status line — is kept. The previous
  file is backed up to `settings.json.bak.<timestamp>` whenever it changes.
- adds the plugin marketplaces and installs the enabled plugins with
  `claude plugin install`

Then run `/skills` and `/plugin` in Claude Code to confirm.

### Codex — `install.sh`

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

Skills and `AGENTS.md` are symlinked, so `git pull` updates them in place.
Re-run the install scripts (both are idempotent) after a pull that adds
skills or changes `claude/` settings.

To share a Claude Code settings change with your other machines, copy it into
`claude/settings.json` (or `claude/settings.macos.json`), commit, and push.
