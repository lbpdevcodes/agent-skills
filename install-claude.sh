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
# - Merges claude/settings.json (plus claude/settings.macos.json on macOS) into
#   ~/.claude/settings.json: enabled plugins, plugin marketplaces, model effort,
#   theme. Keys the repo doesn't set — hooks, permissions — are left alone, and
#   the previous file is backed up whenever it changes. Needs jq.
# - Adds those marketplaces and installs those plugins with the `claude` CLI,
#   so they're ready on first launch.
#
# Idempotent: safe to re-run after every pull.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skills_target="${HOME}/.claude/skills"
claude_md="${HOME}/.claude/CLAUDE.md"
settings_json="${HOME}/.claude/settings.json"

settings_files=("$repo_dir/claude/settings.json")
if [ "$(uname -s)" = "Darwin" ]; then
  settings_files+=("$repo_dir/claude/settings.macos.json")
fi

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

if ! command -v jq >/dev/null 2>&1; then
  echo "WARNING: jq not found — settings and plugins not installed." >&2
  echo "         Install jq and re-run." >&2
  warnings=$((warnings + 1))
else
  [ -e "$settings_json" ] || echo '{}' > "$settings_json"
  merged="$(jq -s 'reduce .[] as $settings ({}; . * $settings)' "$settings_json" "${settings_files[@]}")"
  if [ "$merged" = "$(jq . "$settings_json")" ]; then
    echo "current  $settings_json"
  else
    backup="$settings_json.bak.$(date +%Y%m%d%H%M%S)"
    cp "$settings_json" "$backup"
    printf '%s\n' "$merged" > "$settings_json"
    echo "merged   $settings_json (previous saved to $backup)"
  fi

  if ! command -v claude >/dev/null 2>&1; then
    echo "WARNING: claude CLI not found — plugins not installed." >&2
    echo "         Claude Code will offer to install them on next launch." >&2
    warnings=$((warnings + 1))
  else
    while IFS= read -r marketplace; do
      if claude plugin marketplace add "$marketplace" >/dev/null; then
        echo "added    marketplace $marketplace"
      else
        echo "WARNING: could not add marketplace $marketplace" >&2
        warnings=$((warnings + 1))
      fi
    done < <(jq -r '.extraKnownMarketplaces // {} | .[].source | select(.source == "github") | .repo' "${settings_files[@]}")

    while IFS= read -r plugin; do
      if claude plugin install "$plugin" --scope user >/dev/null; then
        echo "plugin   $plugin"
      else
        echo "WARNING: could not install plugin $plugin" >&2
        warnings=$((warnings + 1))
      fi
    done < <(jq -r '.enabledPlugins // {} | to_entries[] | select(.value) | .key' "${settings_files[@]}")
  fi
fi

echo
if [ "$warnings" -gt 0 ]; then
  echo "Done with $warnings warning(s) — see above."
  exit 1
fi
echo "Done. Run /skills in Claude Code to confirm the skills are discovered."
