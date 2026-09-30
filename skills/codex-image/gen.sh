#!/usr/bin/env bash
# codex-image — generate images with GPT Image 2 via Codex CLI (ChatGPT subscription, no API key).
# https://github.com/mishagavura/claude-code-image-generation · MIT
#
# Usage:
#   gen.sh -o OUT.png [-n N] [-r REF.png]... [-e EDIT.png] [-t] [-a ASPECT] "prompt"
#
#   -o PATH    output file (required). With -n > 1, files become OUT-1.png, OUT-2.png, ...
#   -n N       number of variants (default 1, max 4)
#   -r FILE    reference image for style/composition (repeatable)
#   -e FILE    image to edit (changes only what the prompt asks)
#   -t         transparent background
#   -a ASPECT  square | portrait | landscape (default: model decides)
#
# Prints the saved path(s), one per line. Exit 1 if nothing was generated.
set -euo pipefail

out="" n=1 edit="" transparent=0 aspect=""
refs=()
while getopts "o:n:r:e:ta:" opt; do
  case $opt in
    o) out=$OPTARG ;;
    n) n=$OPTARG ;;
    r) refs+=("$OPTARG") ;;
    e) edit=$OPTARG ;;
    t) transparent=1 ;;
    a) aspect=$OPTARG ;;
    *) sed -n '2,16p' "$0"; exit 2 ;;
  esac
done
shift $((OPTIND - 1))
prompt="${*:-}"
[[ -z $out || -z $prompt ]] && { sed -n '2,16p' "$0"; exit 2; }
(( n < 1 || n > 4 )) && { echo "-n must be 1-4" >&2; exit 2; }
command -v codex >/dev/null || { echo "codex CLI not found. Install: npm i -g @openai/codex && codex login" >&2; exit 1; }
codex login status >/dev/null 2>&1 || { echo "Codex is not logged in. Run: codex login (sign in with ChatGPT)" >&2; exit 1; }


gen_dir="${CODEX_HOME:-$HOME/.codex}/generated_images"
mkdir -p "$gen_dir" "$(dirname "$out")"
marker=$(mktemp); trap 'rm -f "$marker"' EXIT
sleep 1  # make sure new files are strictly newer than the marker

img_args=()
spec="Use your built-in image_gen tool (GPT Image 2). Do not write code, do not use the CLI fallback, do not copy or move files; just generate and then reply DONE."
if [[ -n $edit ]]; then
  img_args+=(-i "$edit")
  spec+=$'\n'"Edit the attached image: change only what the request asks, keep everything else unchanged."
fi
nrefs=0
for r in ${refs[@]+"${refs[@]}"}; do img_args+=(-i "$r"); nrefs=$((nrefs + 1)); done
(( nrefs )) && spec+=$'\n'"The other attached image(s) are references for style/composition only."
(( transparent )) && spec+=$'\n'"Background must be genuinely transparent (preserve alpha)."
[[ -n $aspect ]] && spec+=$'\n'"Aspect ratio: $aspect."
(( n > 1 )) && spec+=$'\n'"Make $n distinct variants: call image_gen $n separate times."
spec+=$'\n\n'"Request: $prompt"

log=$(mktemp)
if ! codex exec --skip-git-repo-check --ephemeral -s read-only \
      --json -c model_reasoning_effort='"low"' ${img_args[@]+"${img_args[@]}"} -- "$spec" </dev/null >"$log" 2>&1; then
  echo "codex exec failed:" >&2; tail -20 "$log" >&2; rm -f "$log"; exit 1
fi
# Each run saves into generated_images/<thread_id>/ — use only this run's folder (safe for parallel runs)
thread=$(grep -o '"thread_id":"[^"]*"' "$log" | head -1 | cut -d'"' -f4 || true)
rm -f "$log"
[[ -n $thread && -d $gen_dir/$thread ]] && gen_dir="$gen_dir/$thread"

# Collect images Codex saved during this run, oldest first
new=()
while IFS= read -r f; do new+=("$f"); done < <(
  find "$gen_dir" -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.webp' \) -newer "$marker" \
    -print0 | { xargs -0 -I{} sh -c 'stat -f "%m %N" "$1" 2>/dev/null || stat -c "%Y %n" "$1"' _ {} ; } | sort -n | cut -d' ' -f2-)
(( ${#new[@]} )) || { echo "No image was generated (check 'codex login status' and usage limits)." >&2; exit 1; }

ext=".${out##*.}"; base="${out%.*}"
[[ $ext == ".$out" ]] && { ext=".png"; base=$out; }
if (( ${#new[@]} == 1 )); then
  dest="$base$ext"; [[ -e $dest ]] && dest="$base-$(date +%H%M%S)$ext"
  cp "${new[0]}" "$dest"; echo "$(cd "$(dirname "$dest")" && pwd)/$(basename "$dest")"
else
  i=1
  for f in "${new[@]}"; do
    dest="$base-$i$ext"; [[ -e $dest ]] && dest="$base-$i-$(date +%H%M%S)$ext"
    cp "$f" "$dest"; echo "$(cd "$(dirname "$dest")" && pwd)/$(basename "$dest")"
    i=$((i + 1))
  done
fi
