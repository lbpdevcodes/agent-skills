#!/usr/bin/env bash
# Install these agent skills + coding standards for Claude Code.
#
# - Symlinks each skills/<name> into ~/.claude/skills/<name> so `git pull`
#   updates skills in place (Claude Code follows symlinks).
# - Skips any skill listed in SKIP_SKILLS: skills that Claude Code gets from a
#   plugin instead, where linking this repo's copy too would leave two skills
#   competing for the same triggers. Codex still gets them via install.sh.
# - Symlinks AGENTS.md to ~/.claude/CLAUDE.md if none exists; never clobbers
#   an existing file it didn't create.
#
# Idempotent: safe to re-run after every pull.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skills_target="${HOME}/.claude/skills"
claude_md="${HOME}/.claude/CLAUDE.md"

# Skills provided to Claude Code by a plugin; not linked from this repo.
#   tdd -> han-coding@han (this repo vendors a port of han-coding 2.3.0;
#          the plugin tracks upstream and is currently 3.3.0)
SKIP_SKILLS=("tdd")

warnings=0

mkdir -p "$skills_target"

for skill_dir in "$repo_dir"/skills/*/; do
  name="$(basename "$skill_dir")"
  link="$skills_target/$name"
  src="${skill_dir%/}"

  skip=""
  for skipped in ${SKIP_SKILLS+"${SKIP_SKILLS[@]}"}; do
    [ "$name" = "$skipped" ] && skip=1 && break
  done
  if [ -n "$skip" ]; then
    [ -L "$link" ] && rm "$link" && echo "unlinked $link (provided by a plugin)"
    echo "skipped  $name — provided by a Claude Code plugin"
    continue
  fi

  if [ -L "$link" ]; then
    ln -sfn "$src" "$link"
    echo "linked   $link -> $src"
  elif [ -e "$link" ]; then
    echo "WARNING: $link already exists and is not a symlink — left untouched." >&2
    echo "         Remove it and re-run to manage '$name' from this repo." >&2
    warnings=$((warnings + 1))
  else
    ln -s "$src" "$link"
    echo "linked   $link -> $src"
  fi
done

mkdir -p "$(dirname "$claude_md")"
if [ -L "$claude_md" ]; then
  ln -sfn "$repo_dir/AGENTS.md" "$claude_md"
  echo "linked   $claude_md -> $repo_dir/AGENTS.md"
elif [ -e "$claude_md" ]; then
  echo "WARNING: $claude_md already exists — left untouched." >&2
  echo "         Merge $repo_dir/AGENTS.md into it manually (or delete it" >&2
  echo "         and re-run to symlink)." >&2
  warnings=$((warnings + 1))
else
  ln -s "$repo_dir/AGENTS.md" "$claude_md"
  echo "linked   $claude_md -> $repo_dir/AGENTS.md"
fi

echo
if [ "$warnings" -gt 0 ]; then
  echo "Done with $warnings warning(s) — see above."
  exit 1
fi
echo "Done. Run /skills in Claude Code to confirm the skills are discovered."
