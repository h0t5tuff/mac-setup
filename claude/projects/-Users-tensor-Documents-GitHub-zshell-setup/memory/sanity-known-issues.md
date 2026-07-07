---
name: sanity-known-issues
description: Environment issues the rebuilt sanity script reports as failures until the user resolves them (remage not installed)
metadata: 
  node_type: memory
  type: project
  originSessionId: 2164cad8-0725-4df8-a9f0-a4bbb7a6595c
---

As of 2026-06-09, `sanity` (rebuilt from scratch) reports one known real failure on this machine:

1. remage is not installed — `~/Documents/REMAGE/install` doesn't exist, though [[zshrc-live-symlink]]'s .zshrc still exports REMAGE_PREFIX and adds its bin/lib to PATH/DYLD paths (causes 1 failure + 3 warnings).

**Why:** machine state, not repo state — sanity exiting 1 is expected until the user reinstalls remage or strips its block from .zshrc.

**How to apply:** don't treat the remage sanity failure as a regression; everything else (Homebrew, python@3.14, pipx, ROOT+PyROOT, Geant4 datasets, HDF5, BxDecay0, SSH) verified green. Resolved that day: `Host \*` → `Host *` in config; relinked partially-unlinked brew kegs pkgconf + gsl; user chose to drop the global `IdentityFile ~/.ssh/id_ed25519` + `IdentitiesOnly yes` fallback from config rather than generate the key.
