#!/usr/bin/env bash
# Install these agent skills + AGENTS.md for OpenAI Codex (CLI / IDE extension).
#
# - Symlinks each skills/<name> into ~/.agents/skills/<name> so `git pull`
#   updates skills in place (Codex follows symlinks).
# - Symlinks AGENTS.md to ~/.codex/AGENTS.md if none exists; never clobbers
#   an existing file it didn't create.
#
# Idempotent: safe to re-run after every pull.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skills_target="${HOME}/.agents/skills"
codex_agents_md="${HOME}/.codex/AGENTS.md"

warnings=0

mkdir -p "$skills_target"

for skill_dir in "$repo_dir"/skills/*/; do
  name="$(basename "$skill_dir")"
  link="$skills_target/$name"
  src="${skill_dir%/}"

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

mkdir -p "$(dirname "$codex_agents_md")"
if [ -L "$codex_agents_md" ]; then
  ln -sfn "$repo_dir/AGENTS.md" "$codex_agents_md"
  echo "linked   $codex_agents_md -> $repo_dir/AGENTS.md"
elif [ -e "$codex_agents_md" ]; then
  echo "WARNING: $codex_agents_md already exists — left untouched." >&2
  echo "         Merge $repo_dir/AGENTS.md into it manually (or delete it" >&2
  echo "         and re-run to symlink)." >&2
  warnings=$((warnings + 1))
else
  ln -s "$repo_dir/AGENTS.md" "$codex_agents_md"
  echo "linked   $codex_agents_md -> $repo_dir/AGENTS.md"
fi

echo
if [ "$warnings" -gt 0 ]; then
  echo "Done with $warnings warning(s) — see above."
  exit 1
fi
echo "Done. Run /skills in Codex to confirm the skills are discovered."
