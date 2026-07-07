---
name: zshrc-live-symlink
description: "~/.zshrc symlinks to this repo's .zshrc — edits to the repo file are immediately live"
metadata: 
  node_type: memory
  type: project
  originSessionId: bc5ae681-ffec-42bf-86db-ef8ef015fb2b
---

`~/.zshrc` is a symlink to this repo's `.zshrc` (`/Users/tensor/Documents/GitHub/mac-setup/.zshrc` — repo renamed from zshell-setup on 2026-06-09). Editing the repo file changes the user's live shell config immediately — there is no separate copy/install step. Confirmed 2026-06-08 via `ls -la ~/.zshrc`.

The main Python is Homebrew `python@3.14` on Apple Silicon, wired up by the interactive-only `arm64()` function. Non-zsh / non-interactive contexts (scripts, cron, GUI apps, `brew doctor` run from bash) fall back to Apple's `/usr/bin/python3` (3.9.6) — this is expected, not a bug.
