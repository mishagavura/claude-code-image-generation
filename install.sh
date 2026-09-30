#!/usr/bin/env bash
# Claude Code Image Generation (GPT Image 2) — installer
#   curl -fsSL https://raw.githubusercontent.com/mishagavura/claude-code-image-generation/main/install.sh | bash
#   npx -y github:mishagavura/claude-code-image-generation
#   ./install.sh            # from a clone → ~/.claude/skills (all projects)
#   ./install.sh --project  # → ./.claude/skills (current project only)
#   ./install.sh --yes      # don't ask, install/log in to Codex automatically where possible
set -euo pipefail

REPO="https://github.com/mishagavura/claude-code-image-generation"
dest="$HOME/.claude/skills"; assume_yes=0
for arg in "$@"; do
  case $arg in
    --project) dest="$PWD/.claude/skills" ;;
    --yes|-y)  assume_yes=1 ;;
  esac
done

bold=$'\033[1m'; green=$'\033[32m'; yellow=$'\033[33m'; reset=$'\033[0m'
ok()   { echo "${green}✓${reset} $*"; }
warn() { echo "${yellow}!${reset} $*"; }

has_tty() { { : > /dev/tty; } 2>/dev/null; }

# Ask a yes/no question even when piped from curl (reads the terminal directly)
ask() {
  (( assume_yes )) && return 0
  has_tty || return 1
  local reply; printf '%s [Y/n] ' "$1" > /dev/tty; read -r reply < /dev/tty || return 1
  [[ -z $reply || $reply =~ ^[Yy] ]]
}

echo "${bold}Claude Code Image Generation — GPT Image 2 via Codex CLI${reset}"

# 1. Copy the skill
src=""
here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [[ -n $here && -f $here/skills/codex-image/SKILL.md ]]; then
  src="$here/skills/codex-image"
else
  command -v git >/dev/null || { echo "git is required"; exit 1; }
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  git clone --depth 1 -q "$REPO" "$tmp/repo"
  src="$tmp/repo/skills/codex-image"
fi
mkdir -p "$dest"
rm -rf "$dest/codex-image"
cp -R "$src" "$dest/codex-image"
chmod +x "$dest/codex-image/gen.sh"
ok "Skill installed → $dest/codex-image"

# 2. Codex CLI
if ! command -v codex >/dev/null; then
  if command -v npm >/dev/null && ask "Codex CLI is not installed. Install it now (npm i -g @openai/codex)?"; then
    npm i -g @openai/codex >/dev/null && ok "Codex CLI installed"
  else
    warn "Install Codex CLI:  ${bold}npm i -g @openai/codex${reset}   (needs Node.js 18+)"
  fi
fi

# 3. ChatGPT login
if command -v codex >/dev/null; then
  if codex login status >/dev/null 2>&1; then
    ok "Codex is signed in"
  elif has_tty && ask "Sign in to Codex with your ChatGPT account now?"; then
    codex login < /dev/tty && ok "Codex is signed in"
  else
    warn "Sign in:  ${bold}codex login${reset}   (choose \"Sign in with ChatGPT\")"
  fi
fi

echo
echo "${bold}Done.${reset} Restart Claude Code, then just ask:"
echo "  \"Generate a watercolor hero image of a spring plant market\""
echo "or type:  /codex-image a product photo of a ceramic mug on a wood table"
