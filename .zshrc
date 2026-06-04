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
alias dds='ls -hFGlast -tr; \
  echo -n "Size: "; du -sh . | cut -f1; \
  echo -n " Entries (curr): "; find . -mindepth 1 -maxdepth 1 | wc -l; \
  echo -n " Entries (all): "; find . -mindepth 1 | wc -l'
alias werb='brew update && brew upgrade && brew autoremove && brew cleanup && brew doctor'
alias vscodefix='echo "Run: Cmd+Shift+P → Shell Command: Install `code` in PATH"'
#ROOT
r() {
  if [[ ! -f "$1" ]]; then
    echo "eeestupidooo"
    return 1
  fi
  root -l "$1" -e 'new TBrowser();'
}
# DAQ
cpyc() { scp daq:~/ROOT/bacon2Data/compiledGold/"$1" . }
cpyb() { scp daq:~/ROOT/bacon2Data/bobjGold/"$1" . }
cpybm() { scp "$1" daq:/home/bacon/BaconMonitor/ }

# ╭───────────────────────────────╮
# │         zsh PATH handling     │
# ╰───────────────────────────────╯
typeset -gU path
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

  # Homebrew
  eval "$(/opt/homebrew/bin/brew shellenv)"

  #source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  #source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

  # Python
  path=(/opt/homebrew/opt/python@3.12/libexec/bin /opt/homebrew/opt/python@3.12/bin $path)
  export Python3_EXECUTABLE="/opt/homebrew/opt/python@3.12/bin/python3.12"

  # ROOT
  pushd /opt/homebrew > /dev/null
  . bin/thisroot.sh
  popd > /dev/null
  export ROOT_DIR="/opt/homebrew/opt/root/share/root/cmake"

  # User
  export PATH="/usr/local/bin:$PATH"

  # Ensure PATH uniqueness
  typeset -gU path
}

# ╭───────────────────────────────╮
# │           💽 Intel            │
# ╰───────────────────────────────╯
amd64() {
  reset_env_paths
  export ENV_FLAVOR="🖥️"

  # Homebrew
  eval "$(/usr/local/bin/brew shellenv)"

  # User
  export PATH="/usr/local/bin:$PATH"

  # Ensure PATH uniqueness
  typeset -gU path
}

# ╭───────────────────────────────╮
# │      ⚡ Default Env            │
# ╰───────────────────────────────╯
export PIPX_DEFAULT_PYTHON=/opt/homebrew/opt/python@3.12/bin/python3.12
export PATH="$PATH:/Users/tensor/.local/bin"
alias jn='jupyter-notebook'
alias v="source ~/venvs/v/bin/activate" 
if [[ -o interactive ]]; then
  arm64 
fi


# ╭───────────────────────────────╮
# │  ☢️ Physics Simulation Stack  │
# ╰───────────────────────────────╯
# HDF5               
export HDF5_ROOT="$HOME/Documents/HDF5/install-hdf5-1_14_3"
export HDF5_DIR="$HDF5_ROOT/cmake"
path=("$HDF5_ROOT/bin" $path)
export PKG_CONFIG_PATH="$HDF5_ROOT/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

# Geant4                 
export GEANT4_BASE="$HOME/Documents/GEANT4/install-v11.4.0"
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
export REMAGE_PREFIX="$REMAGE_HOME/install"
path=("$REMAGE_PREFIX/bin" $path)

# path stuff
export CMAKE_PREFIX_PATH="$HDF5_ROOT;$BXDECAY0_PREFIX;$GEANT4_BASE;/opt/homebrew/opt/root;/opt/homebrew;${CMAKE_PREFIX_PATH:-}"
export DYLD_FALLBACK_LIBRARY_PATH="$HDF5_ROOT/lib:$GEANT4_BASE/lib:$BXDECAY0_PREFIX/lib:$REMAGE_PREFIX/lib:${DYLD_FALLBACK_LIBRARY_PATH:-}"


# ╭───────────────────────────────╮
# │         ☢️ Sims               │
# ╰───────────────────────────────╯
# bacon2Data          
export BACONHOME="$HOME/Documents/ROOT"
export BOBJ="$HOME/Documents/ROOT/bacon2Data/bobj"
export COMPILED="$HOME/Documents/ROOT/bacon2Data/compiled"
path=("$BOBJ" "$COMPILED" "$BACONHOME" $path)
typeset -gU path

# BACONCALIBRATIONSIMULATION 