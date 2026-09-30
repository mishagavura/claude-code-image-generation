#!/usr/bin/env bash
# Install the codex-image skill for Claude Code.
#   curl -fsSL https://raw.githubusercontent.com/mishagavura/codex-image-skill/main/install.sh | bash
#   ./install.sh            # from a clone → ~/.claude/skills (all projects)
#   ./install.sh --project  # → ./.claude/skills (this project only)
set -euo pipefail

REPO="https://github.com/mishagavura/codex-image-skill"
dest="$HOME/.claude/skills"
[[ ${1:-} == --project ]] && dest="$PWD/.claude/skills"

src=""
here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [[ -n $here && -f $here/skills/codex-image/SKILL.md ]]; then
  src="$here/skills/codex-image"
else
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  echo "Downloading codex-image…"
  git clone --depth 1 -q "$REPO" "$tmp/repo"
  src="$tmp/repo/skills/codex-image"
fi

mkdir -p "$dest"
rm -rf "$dest/codex-image"
cp -R "$src" "$dest/codex-image"
chmod +x "$dest/codex-image/gen.sh"
echo "✓ Installed to $dest/codex-image"

if ! command -v codex >/dev/null; then
  echo "! Codex CLI not found. Install it:  npm i -g @openai/codex  then  codex login"
elif ! codex login status >/dev/null 2>&1; then
  echo "! Codex is installed but not logged in. Run:  codex login  (sign in with ChatGPT)"
else
  echo "✓ Codex CLI is ready"
fi
echo "Restart Claude Code, then ask it to generate an image."
