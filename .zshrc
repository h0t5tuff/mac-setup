# ╭───────────────────────────────────────╮
# │        ⚡ Prompt & Git                 │
# ╰───────────────────────────────────────╯
parse_git_status() {
  git rev-parse --is-inside-work-tree &>/dev/null || return
  local branch dirty ahead behind
  branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  [[ -z $(git status --porcelain 2>/dev/null) ]] && dirty="✓" || dirty="✗"
  if git rev-parse @{u} &>/dev/null; then
    read -r behind ahead <<<"$(git rev-list --left-right --count @{u}...HEAD 2>/dev/null)"
    ((ahead)) && ahead="↑$ahead" || ahead=""
    ((behind)) && behind="↓$behind" || behind=""
  else
    ahead=""
    behind=""
  fi
  echo "%F{blue}[$branch $dirty$ahead$behind]%f"
}
setopt prompt_subst
PROMPT='${ENV_FLAVOR} %F{green}τενΣΩρ%f %F{green}%~%f %F{magenta}$(parse_git_status)%f '

# ╭───────────────────────────────╮
# │          ⚡ Aliases            │
# ╰───────────────────────────────╯
alias dds='ls -halsF -tr --color=auto'
alias dss='ls -hFGlast -tr; \
  echo -n "Size: "; du -sh . | cut -f1; \
  echo -n " Entries (curr): "; find . -mindepth 1 -maxdepth 1 | wc -l; \
  echo -n " Entries (all): "; find . -mindepth 1 | wc -l'
  
alias werb='brew update && brew upgrade && brew autoremove && brew cleanup && brew doctor'
alias vscodefix='echo "Run: Cmd+Shift+P → Shell Command: Install code in PATH"'
#ROOT
r() {
  if [[ ! -f "$1" ]]; then
    echo "Usage: r <root_file>"
    return 1
  fi
  root -l "$1" -e 'new TBrowser();'
}
# DAQ
scpbm() { 
  if [[ ! -f "$1" ]]; then
    echo "Usage: scpbm <local_file>"
    return 1
  fi
  scp "$1" daqTensor:/home/bacon/BaconMonitor/ 
}
scpdaq() {
    ssh -t daqTensor "sudo chmod 644 \"$1\"" &&
    scp "daqTensor:$1" .
}
# NERSC
scpdqcpdfs() {
    local period="$1"
    local run="$2"
    if [[ -z "$period" || -z "$run" ]]; then
        echo "Usage: scpdqcpdfs <period> <run>"
        return 1
    fi
    scp -r "nersc:/global/cfs/cdirs/m2676/users/calgaro/legend-data-monitor/monitoring/automatic_prod/dashboard/auto/latest/generated/plt/hit/phy/${period}/${run}/mtg/pdf" \
        "$HOME/Library/Mobile Documents/com~apple~CloudDocs/0νββ/legend shifts/${period}_${run}"
}
scppng() {
    if [[ -z "$1" ]]; then
        echo "Usage: scppng <dir name>"
        return 1
    fi

    local name="$1"
    local remote="/global/cfs/cdirs/legend/users/Tensor/shifter/$name"
    local dest="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Downloads/$name"

    mkdir -p "$dest" || return 1

    rsync -avm \
        --include='*/' \
        --include='*.png' \
        --exclude='*' \
        "nersc:${remote}/" \
        "${dest}/"
}

# ╭───────────────────────────────╮
# │         zsh PATH handling     │
# ╰───────────────────────────────╯
typeset -gU path
HOMEBREW_PYTHON=/opt/homebrew/opt/python@3.14
use_homebrew_python() {
  [[ -d $HOMEBREW_PYTHON/bin ]] || return
  path=("$HOMEBREW_PYTHON/libexec/bin" "$HOMEBREW_PYTHON/bin" $path)
  export Python3_EXECUTABLE="$HOMEBREW_PYTHON/bin/python3"
}

# ╭───────────────────────────────╮
# │       🔁 Env Reset Logic      │
# ╰───────────────────────────────╯
reset_env_paths() {
  local -a newpath
  local p
  for p in $path; do
    [[ "$p" == /opt/homebrew* || "$p" == /usr/local* ]] && continue
    newpath+=("$p")
  done
  path=(/usr/bin /bin /usr/sbin /sbin $newpath)
  export LDFLAGS=""
  export CPPFLAGS=""
  export PKG_CONFIG_PATH=""
}

# ╭───────────────────────────────╮
# │       🍎 AppleSilicon         │
# ╰───────────────────────────────╯
arm64() {
  reset_env_paths
  export ENV_FLAVOR="💻"

  # Homebrew (scalar PATH edit)
  eval "$(/opt/homebrew/bin/brew shellenv)"
  use_homebrew_python

  # ROOT (scalar PATH edit)
  pushd /opt/homebrew > /dev/null
  . bin/thisroot.sh
  popd > /dev/null
  export ROOT_DIR="/opt/homebrew/opt/root/share/root/cmake"

  path=(/usr/local/bin $path)
}

# ╭───────────────────────────────╮
# │           💽 Intel            │
# ╰───────────────────────────────╯
amd64() {
  reset_env_paths
  export ENV_FLAVOR="🖥️"

  # Homebrew — the /usr/local prefix already adds /usr/local/bin to PATH
  eval "$(/usr/local/bin/brew shellenv)"
  typeset -gU path
}

# ╭───────────────────────────────╮
# │      ⚡ Default Env            │
# ╰───────────────────────────────╮
export PIPX_DEFAULT_PYTHON="$HOMEBREW_PYTHON/bin/python3"
path+=("$HOME/.local/bin")
alias jn='jupyter-notebook'
alias venv="source ~/venvs/venv/bin/activate"
if [[ -o interactive ]]; then
  if [[ $(uname -m) == arm64 ]]; then arm64; else amd64; fi
fi


# ╭───────────────────────────────╮
# │  ☢️ Physics Simulation Stack  │
# ╰───────────────────────────────╯
# HDF5
export HDF5_ROOT="$HOME/Documents/HDF5/install-hdf5_2.1.0"
export HDF5_DIR="$HDF5_ROOT/cmake"
path=("$HDF5_ROOT/bin" $path)
export PKG_CONFIG_PATH="$HDF5_ROOT/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

# Geant4
export GEANT4_BASE="$HOME/Documents/GEANT4/install-v11.4.2"
if [[ -f "$GEANT4_BASE/bin/geant4.sh" ]]; then
  source "$GEANT4_BASE/bin/geant4.sh"
fi
export Geant4_DIR="$GEANT4_BASE/lib/cmake/Geant4"
path=("$GEANT4_BASE/bin" $path)
export G4VIS_DEFAULT_DRIVER=OGLSQt

# BxDecay0
export BXDECAY0_HOME="$HOME/Documents/BXDECAY0"
export BXDECAY0_PREFIX="$BXDECAY0_HOME/install"
export PKG_CONFIG_PATH="$BXDECAY0_PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

# remage
export REMAGE_HOME="$HOME/Documents/REMAGE"
export REMAGE_PREFIX="$REMAGE_HOME/install-remage-v0.24.0"
path=("$REMAGE_PREFIX/bin" $path)

# legend-metadata (pylegendmeta / dbetto read $LEGEND_METADATA)
export LEGEND_METADATA="$REMAGE_HOME/legend-metadata"

# CMake / dynamic-linker hints for the whole stack
export CMAKE_PREFIX_PATH="$HDF5_ROOT;$BXDECAY0_PREFIX;$GEANT4_BASE;/opt/homebrew/opt/root;/opt/homebrew;${CMAKE_PREFIX_PATH:-}"
export DYLD_FALLBACK_LIBRARY_PATH="$HDF5_ROOT/lib:$GEANT4_BASE/lib:$BXDECAY0_PREFIX/lib:$REMAGE_PREFIX/lib:${DYLD_FALLBACK_LIBRARY_PATH:-}"


# ╭───────────────────────────────╮
# │         ☢️ Sims               │
# ╰───────────────────────────────╮
# bacon2Data
export BACONHOME="$HOME/Documents/ROOT"
export BOBJ="$HOME/Documents/ROOT/bacon2Data/bobj"
export COMPILED="$HOME/Documents/ROOT/bacon2Data/compiled"
export ROOTDATA="$COMPILED/rootData"   # anacg input (per-run raw/sim waveforms)
export CAENDATA="$COMPILED/caenData"   # anacg output / postAna + summary input
path=("$BOBJ" "$COMPILED" "$BACONHOME" $path)
