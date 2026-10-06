# ╭──────────────────────╮
# │        ⚡ Git         │
# ╰──────────────────────╯
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

# ╭─────────────────────────╮
# |        Prompt           |
# ╰─────────────────────────╯
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
alias vscode='echo "Run: Cmd+Shift+P → Shell Command: Install code in PATH"'
#ROOT
r() {
  if [[ -z "$1" ]]; then
    echo "Usage: r <root_file>"
    return 1
  fi
  root -l "$1" -e 'new TBrowser();'
}
# DAQ
scpbm() { 
    if [[ -z "$1" ]]; then
    echo "Usage: scpbm <local_file>"
    return 1
  fi
  scp "$1" daqTensor:/home/bacon/BaconMonitor/ 
}
scpdaq() {
  if [[ -z "$1" ]]; then
    echo "Usage: scpdaq <root_file>"
    return 1
  fi
  ssh -t daqTensor "sudo chmod 644 \"$1\"" &&
  scp "daqTensor:$1" .
}
scpdaqposts() {
  local f='/home/gold/bacon2Data/compiled/post-*.root'
  ssh -t daqTensor "sudo chmod 644 $f" &&
  scp "daqTensor:$f" .
}
# NERSC
scpdqcpdfs() {
    if [[ -z "$1" ]]; then
        echo "Usage: scpdqcpdfs <period> <run>"
        return 1
    fi 
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
# Jupyter lives in ~/venvs/v (not pipx/brew) — call it by path, no activation needed
alias jn='~/venvs/v/bin/jupyter notebook'
alias jl='~/venvs/v/bin/jupyter lab'
alias venv="source ~/venvs/v/bin/activate"
# skip inside `pixi shell`: it inherits an already-set-up PATH, and the reset would
# push Homebrew's cmake/compilers ahead of the pixi env's (mixing C++ runtimes)
if [[ -o interactive && -z ${PIXI_IN_SHELL:-} ]]; then
  if [[ $(uname -m) == arm64 ]]; then arm64; else amd64; fi
elif [[ -n ${PIXI_IN_SHELL:-} ]]; then
  # drop the Homebrew-ROOT vars (thisroot.sh) inherited from the parent shell, so the env's
  # own python/ROOT/cmake are used — same list the bin/ wrappers clear
  unset PYTHONPATH ROOTSYS ROOT_INCLUDE_PATH DYLD_LIBRARY_PATH LD_LIBRARY_PATH LIBPATH SHLIB_PATH \
        JUPYTER_PATH JUPYTER_CONFIG_PATH JUPYTER_CONFIG_DIR CMAKE_PREFIX_PATH
fi


# ╭───────────────────────────────╮
# │  ☢️ Physics Simulation Stack  │
# ╰───────────────────────────────╯
# remage + Geant4 come from pixi (conda-forge) — no source builds. Workspaces in mac-setup/pixi/:
#   remage, remage-cpp   pixi/remage  remage 1.1 (Geant4 11.3, HDF5/LH5 + ROOT output)
#   g4, g4build          pixi/geant4  Geant4 11.4 (Qt) + ROOT + cmake + compilers, for your own apps
# all four are `pixi run` wrappers in ~/.local/bin (mac-setup/bin), so they work from bash scripts too
export G4VIS_DEFAULT_DRIVER=OGLSQt

# legend-metadata (pylegendmeta / dbetto read $LEGEND_METADATA)
export LEGEND_METADATA="$HOME/Documents/Legend-metadata"

# CMake hint: Homebrew ROOT (bacon2Data & co.). Inside the pixi Geant4 env, g4build puts
# $CONDA_PREFIX first so its own ROOT/Geant4 win over these.
[[ -z ${PIXI_IN_SHELL:-} ]] && export CMAKE_PREFIX_PATH="/opt/homebrew/opt/root;/opt/homebrew;${CMAKE_PREFIX_PATH:-}"


# ╭───────────────────────────────╮
# │         ☢️ Sims               │
# ╰───────────────────────────────╮
# bacon2Data
export BACONHOME="$HOME/Documents"    # parent of the repo: bobj/Makefile uses $(BACONHOME)/bacon2Data/bobj
export BOBJ="$HOME/Documents/bacon2Data/bobj"
export COMPILED="$HOME/Documents/bacon2Data/compiled"
export ROOTDATA="$COMPILED/rootData"   # anacg input (per-run raw/sim waveforms)
export CAENDATA="$COMPILED/caenData"   # anacg output / postAna + summary input
path=("$BOBJ" "$COMPILED" "$BACONHOME/bacon2Data" $path)

torrent() { ~/venvs/torrent/bin/python "$HOME/Library/Mobile Documents/com~apple~CloudDocs/MechaTronics/T/torrent_dl.py" "$@"; }
