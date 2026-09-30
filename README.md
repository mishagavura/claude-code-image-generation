# codex-image — GPT Image 2 for Claude Code

Let Claude Code generate and edit images with **OpenAI's GPT Image 2**, using your **ChatGPT subscription**
through the Codex CLI. No OpenAI API key, no per-image billing.

Ask Claude *"make a hero image for the homepage"* or *"remove the background from logo.png"* and it writes the
prompt, runs Codex, checks the result and saves the file where your project needs it.

| Generate | Edit (`-e`) | Landscape (`-a landscape`) |
|---|---|---|
| ![leaf](examples/leaf.jpg) | ![autumn leaf](examples/leaf-autumn.jpg) | ![market stall](examples/var-1.jpg) |
| *"flat illustration of a green oak leaf on a cream background"* | *"make the leaf autumn orange-red, keep everything else"* | *"cozy watercolor of a plant nursery stall at a spring market"* |

## How it works

```
Claude Code ──▶ gen.sh ──▶ codex exec (ChatGPT login) ──▶ built-in image_gen (GPT Image 2)
                   ▲                                              │
                   └──── copies ~/.codex/generated_images/<run> ◀─┘
```

Codex CLI has a built-in image tool that runs on your ChatGPT plan. This skill wraps it in a small script and
teaches Claude when and how to call it.

## Requirements

- [Claude Code](https://claude.com/claude-code)
- [Codex CLI](https://github.com/openai/codex) signed in with ChatGPT:
  ```bash
  npm i -g @openai/codex
  codex login        # choose "Sign in with ChatGPT"
  ```
- A ChatGPT plan that includes image generation in Codex. Images count toward your plan's limits.
- macOS or Linux (bash). Windows: use WSL.

## Install

**Option 1: one line**
```bash
curl -fsSL https://raw.githubusercontent.com/mishagavura/codex-image-skill/main/install.sh | bash
```

**Option 2: Claude Code plugin**
```
/plugin marketplace add mishagavura/codex-image-skill
/plugin install codex-image@codex-image-skill
```

**Option 3: manual**
```bash
git clone https://github.com/mishagavura/codex-image-skill
cd codex-image-skill && ./install.sh             # all projects  → ~/.claude/skills
                        ./install.sh --project   # this project → ./.claude/skills
```

Restart Claude Code afterwards.

## Use

Just ask Claude:

- "Generate a product shot of a bamboo baby onesie on a light wood table"
- "Make 3 variants of a hero banner for a native plant nursery"
- "Edit hero.png: make it golden hour, keep everything else"
- "Create a transparent-background sticker that says 'SALE'"

Or run the script yourself:

```bash
~/.claude/skills/codex-image/gen.sh -o hero.png -a landscape "watercolor of a spring plant market"
```

| Option | Meaning |
|---|---|
| `-o PATH` | Output file (required). `-n` > 1 → `out-1.png`, `out-2.png`, … |
| `-n N` | 1–4 variants |
| `-r FILE` | Reference image for style/composition (repeatable) |
| `-e FILE` | Image to edit |
| `-t` | Transparent background |
| `-a square\|portrait\|landscape` | Aspect ratio |

Each image takes about 30–90 seconds. Parallel runs are safe. Existing files are never overwritten.

## Notes & limits

- **Transparent output** (`-t`) sometimes has semi-transparent blotches. If so, generate on a plain white
  background and remove it with another tool.
- **Limits:** generation uses your ChatGPT plan's image allowance. When it's used up, the script reports that no
  image was generated.
- **Content policy:** OpenAI's usage policies apply; refused prompts produce no image.
- Not affiliated with OpenAI or Anthropic. This skill only drives the official Codex CLI you install and log into yourself.

## License

MIT © Mykhailo Gavura
