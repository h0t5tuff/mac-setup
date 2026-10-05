# Brewfile — the shared formula set for all my Macs.
# Apply:   brew bundle --file ~/Documents/mac-setup/Brewfile
# Verify:  brew bundle check --file ~/Documents/mac-setup/Brewfile
# Only top-level formulae are listed; dependencies come along automatically.

# ── core / pinned ──────────────────────────────────────────────
brew "python@3.14"   # pinned shell python (HOMEBREW_PYTHON in .zshrc), venv ~/venvs/v
brew "libtorrent-rasterbar"   # py3.14 bindings for ~/venvs/torrent (PyPI libtorrent has no 3.14 wheels)
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
brew "hdf5"          # remage LH5 output (Geant4 GEANT4_USE_HDF5=ON); ships the C++ libs remage needs

# ── python / jupyter ───────────────────────────────────────────
brew "pipx"          # standalone CLI tools only (black); NOT jupyter
brew "pandoc"        # nbconvert export (was implicit via jupyterlab)
brew "node"          # jupyter extension builds (was implicit via jupyterlab)

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

# ── LaTeX (VS Code replaces Overleaf) ──────────────────────────
brew "tex-fmt"       # LaTeX formatter (latex-workshop)

# ── media ──────────────────────────────────────────────────────
brew "ffmpeg"
brew "handbrake"     # HandBrakeCLI — burns subtitles in (car videos)

# ── misc ───────────────────────────────────────────────────────
brew "jpeg-xl"
brew "mariadb-connector-c"
brew "cmatrix"
brew "xeyes"

# ── casks ──────────────────────────────────────────────────────
cask "xquartz"       # X11 server (xeyes, X11 forwarding)
cask "mactex-no-gui" # TeX Live; path_helper puts /Library/TeX/texbin on PATH
cask "visual-studio-code"

# ── VS Code extensions ─────────────────────────────────────────
vscode "adpyke.codesnap"
vscode "albertopdrf.root-file-viewer"
vscode "alefragnani.project-manager"
vscode "anthropic.claude-code"
vscode "bierner.markdown-mermaid"
vscode "christian-kohler.path-intellisense"
vscode "codezombiech.gitignore"
vscode "donjayamanne.python-extension-pack"
vscode "eamodio.gitlens"
vscode "esbenp.prettier-vscode"
vscode "formulahendry.code-runner"
vscode "h5web.vscode-h5web"
vscode "james-yu.latex-workshop"
vscode "mechatroner.rainbow-csv"
vscode "mhutchie.git-graph"
vscode "ms-python.debugpy"
vscode "ms-python.isort"
vscode "ms-python.python"
vscode "ms-python.vscode-pylance"
vscode "ms-python.vscode-python-envs"
vscode "ms-toolsai.jupyter"
vscode "ms-toolsai.jupyter-keymap"
vscode "ms-toolsai.jupyter-renderers"
vscode "ms-toolsai.vscode-jupyter-cell-tags"
vscode "ms-toolsai.vscode-jupyter-slideshow"
vscode "ms-vscode-remote.remote-ssh"
vscode "ms-vscode-remote.remote-ssh-edit"
vscode "ms-vscode.cmake-tools"
vscode "ms-vscode.cpp-devtools"
vscode "ms-vscode.cpptools"
vscode "ms-vscode.cpptools-extension-pack"
vscode "ms-vscode.cpptools-themes"
vscode "ms-vscode.makefile-tools"
vscode "ms-vscode.remote-explorer"
vscode "ms-vsliveshare.vsliveshare"
vscode "phisch.phocus-vscode"
vscode "pkief.material-icon-theme"
vscode "pkief.material-product-icons"
vscode "tejasvi.rainbow-brackets-2"
vscode "tomoki1207.pdf"
vscode "wholroyd.jinja"
vscode "ziyasal.vscode-open-in-github"
