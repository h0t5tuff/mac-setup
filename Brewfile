# Brewfile — the shared formula set for all my Macs.
# Apply:   brew bundle --file ~/Documents/GitHub/mac-setup/Brewfile
# Verify:  brew bundle check --file ~/Documents/GitHub/mac-setup/Brewfile
# Only top-level formulae are listed; dependencies come along automatically.

# ── core / pinned ──────────────────────────────────────────────
brew "python@3.14"   # pinned shell python (HOMEBREW_PYTHON in .zshrc)
brew "gsl"           # BxDecay0 dependency (also used by ROOT)
brew "pkgconf"
brew "cmake"
brew "make"
brew "ninja"
brew "expat"
brew "zlib"

# ── physics stack ──────────────────────────────────────────────
brew "root"          # CERN ROOT (PyROOT, bacon2Data)
brew "clhep"
brew "open-mpi"
brew "qt"            # Geant4 OGLSQt vis driver
brew "xerces-c"      # Geant4 GDML
brew "jpeg"
brew "opencascade"

# ── python / jupyter ───────────────────────────────────────────
brew "pipx"
brew "jupyterlab"    # also pulls node + pandoc

# ── shell & editors ────────────────────────────────────────────
brew "zsh"
brew "zsh-autosuggestions"
brew "zsh-completions"
brew "zsh-syntax-highlighting"
brew "neovim"
brew "tmux"

# ── git ────────────────────────────────────────────────────────
brew "git"
brew "git-lfs"

# ── cli tools ──────────────────────────────────────────────────
brew "bat"
brew "htop"
brew "jq"
brew "tree"
brew "wget"
brew "gnupg"

# ── embedded (ESP32 etc.) ──────────────────────────────────────
brew "dfu-util"
brew "esptool"

# ── misc ───────────────────────────────────────────────────────
brew "jpeg-xl"
brew "mariadb-connector-c"
brew "cmatrix"
brew "xeyes"

# ── casks ──────────────────────────────────────────────────────
cask "xquartz"       # X11 server (xeyes, X11 forwarding)
