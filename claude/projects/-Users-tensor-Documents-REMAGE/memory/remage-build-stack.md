---
name: remage-build-stack
description: "Working remage v0.24.0 + BxDecay0 build configuration on this Mac, and the pitfalls hit on 2026-07-07"
metadata: 
  node_type: memory
  type: project
  originSessionId: 559caeed-00e4-42d2-a209-d29f217c0176
---

remage v0.24.0 is built with BxDecay0 v1.2.1 support at `/Users/tensor/Documents/REMAGE/` (build dir `build-remage-v0.24.0`, install prefix `install-remage-v0.24.0`). Stack: Geant4 v11.4.2 at `/Users/tensor/Documents/GEANT4/install-v11.4.2`, HDF5 2.1.0 at `/Users/tensor/Documents/HDF5/install-hdf5_2.1.0`, BxDecay0 at `/Users/tensor/Documents/BXDECAY0/install`.

**Why:** rebuilding after upgrades kept failing on non-obvious issues.

**How to apply:**
- Do NOT pass `-DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON`: Homebrew's `XercesCConfig.cmake` lacks an `if(NOT TARGET)` guard and dies on duplicate `XercesC::XercesC` via Geant4's find_dependency. Instead add `/opt/homebrew/opt/xerces-c` (keg-only) to `CMAKE_PREFIX_PATH` so module-mode FindXercesC works.
- remage's Python CLI wrapper needs Python 3.11–3.13; use `/opt/homebrew/bin/python3.13` (`-DPython3_EXECUTABLE`). Python 3.14 fails because pyg4ometry has no cp314 wheels. `/usr/local/bin/python3.13` is a broken Intel-brew symlink.
- The HDF5 1.14.3 → 2.1.0 upgrade (libhdf5.310 → .320) broke the old BxDecay0 install; BxDecay0 was rebuilt 2026-07-07 against current Geant4 (no HDF5 dep now). When building BxDecay0 with `BXDECAY0_INSTALL_DBD_GA_DATA=ON`, prepend `/opt/homebrew/Cellar/git-lfs/3.7.1/bin` to PATH (git-lfs is installed but unlinked) and pass `-DGIT_LFS_EXECUTABLE=...`.
- Geant4 v11.4.2 was built WITHOUT HDF5 support, so remage has no LH5/HDF5 output persistency (runs fine, "Object persistency disabled"). Rebuilding Geant4 with `-DGEANT4_USE_HDF5=ON` against HDF5 2.1.0 would restore it.
- Installed remage needs runtime env: `PATH=$PREFIX/bin:$PATH` and `DYLD_FALLBACK_LIBRARY_PATH=$PREFIX/lib:$GEANT4/lib:$BXDECAY0/lib` (installed binaries have no LC_RPATH).
- The user's `build-remage.sh` / `build-bxdecay0.sh` scripts in these dirs are interactive (read prompts) and reference the stale HDF5 path and PREFER_CONFIG flag.
