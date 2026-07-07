---
name: geant4-setup
description: "Geant4 11.4.2 install layout, how to build/run against it from tool shells"
metadata: 
  node_type: memory
  type: project
  originSessionId: 89d385ff-94d6-4353-a73e-a197c0dac3a1
---

Geant4 11.4.2 is installed at `~/Documents/GEANT4/install-v11.4.2` (source in `geant4/`, build in `build-v11.4.2/`). Verified working end-to-end 2026-07-07 (example B1, 10k events).

- Tool (non-interactive) shells do NOT load `~/.zshrc`, so no Geant4 env is present: `source ~/Documents/GEANT4/install-v11.4.2/bin/geant4.sh` before running apps, and pass `-DGeant4_DIR=~/Documents/GEANT4/install-v11.4.2/lib/cmake/Geant4` to cmake. The user's interactive zsh already has everything (zshrc lines ~141-162, incl. `GEANT4_BASE`, `Geant4_DIR`, `G4VIS_DEFAULT_DRIVER=OGLSQt`).
- In Geant4 11.4 only `GEANT4_DATA_DIR` matters; per-dataset `G4*DATA` vars are intentionally commented out in geant4.sh — their absence is not a problem.
- Build has GDML on → needs Homebrew xerces-c ≥3.3.0. Its symlinks were half-broken (lib linked, headers not) and fixed 2026-07-07 via `brew unlink xerces-c && brew link xerces-c`. If "Failed to find XercesC" reappears after a brew upgrade, relink again.
- Active projects in the dir: `BACONCalibrationSimulation`, `geant4-11-tutorial`.
