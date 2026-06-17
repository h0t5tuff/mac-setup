# mac-setup

My macOS shell environment, version-controlled. Three files are **symlinked**
into place — edits here go live instantly, and `git pull` keeps every machine in
sync. `.zshrc` auto-detects the CPU and loads the `arm64` (💻) or `amd64` (🖥️)
profile.

| repo file | symlinked to | what it is |
| --- | --- | --- |
| `.zshrc`  | `~/.zshrc` | prompt, aliases, Homebrew/Python, physics-stack env |
| `config`  | `~/.ssh/config` | SSH defaults + hosts (github, daq, nersc) |
| `sanity`  | `~/sanity`, `~/.local/bin/sanity` | full system health check |

## Bootstrap a new Mac

```sh
# 1 — prerequisites
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2 — clone + symlink (backs up real dotfiles, not existing symlinks)
mkdir -p ~/Documents/GitHub ~/.ssh ~/.local/bin && chmod 700 ~/.ssh
cd ~/Documents/GitHub && git clone https://github.com/h0t5tuff/mac-setup.git
REPO=~/Documents/GitHub/mac-setup
[ -f ~/.zshrc ]      && [ ! -L ~/.zshrc ]      && mv ~/.zshrc ~/.zshrc.backup
[ -f ~/.ssh/config ] && [ ! -L ~/.ssh/config ] && mv ~/.ssh/config ~/.ssh/config.backup
ln -sfn "$REPO/.zshrc" ~/.zshrc
ln -sfn "$REPO/config" ~/.ssh/config
ln -sfn "$REPO/sanity" ~/sanity
ln -sfn ~/sanity       ~/.local/bin/sanity
chmod +x "$REPO/sanity"

# 3 — brew formulae (top-level only; deps follow). Casks: xquartz.
brew bundle --file "$REPO/Brewfile"
```

Open a **new terminal** (so `python3` = Homebrew 3.14), then do Python, SSH, and
the physics stack below. Finish with `sanity`.

## Python / Jupyter

```sh
# standalone CLI tools (jn alias → jupyter-notebook)
pipx install notebook jupyterlab black
pipx inject jupyterlab jupyterlab_widgets   # ipywidgets frontend half;
pipx inject notebook  jupyterlab_widgets    # kernel half is in the venv below

# main venv at ~/venvs/v  (v alias activates it)
python3 -m venv ~/venvs/v                    # python3 = Homebrew 3.14
source ~/venvs/v/bin/activate
pip install --upgrade pip
pip install ipykernel ipywidgets numpy matplotlib seaborn pandas scipy
pip install awkward hist legend-pydataobj dspeed pylegendmeta dbetto   # LEGEND
python -m ipykernel install --user --name v --display-name "Python 3.14 (v)"
deactivate
```

The kernel registers user-wide (`~/Library/Jupyter/kernels/`), so the pipx
Jupyter shows **Python 3.14 (v)** without living in the venv. Rebuild anytime:
`rm -rf ~/venvs/v` and repeat. LEGEND pip names ≠ import names:

| import | pip package |
| --- | --- |
| `lgdo`, `lh5` | `legend-pydataobj` |
| `legendmeta` | `pylegendmeta` |
| `dspeed`, `dbetto`, `awkward`, `hist` | (same name) |

## SSH

`config` sets global defaults (keep-alive, connection multiplexing w/ 12 h
persist, Keychain-backed agent, no GSSAPI/X11) plus one key per host:

| host | target | key |
| --- | --- | --- |
| `github.com` | github.com | `~/.ssh/id_ed25519_github` |
| `daq` | 64.106.63.220 · user `Tensor` | `~/.ssh/id_ed25519_daq` |
| `nersc` | perlmutter.nersc.gov · user `tens0r` | `~/.ssh/nersc` + `nersc-cert.pub` |

**github + daq** — copy the keys from the old Mac (keep perms) or generate fresh:

```sh
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_github
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_daq
chmod 600 ~/.ssh/id_ed25519_*
```

- **github** → paste `id_ed25519_github.pub` into GitHub → Settings → SSH keys
- **daq** → `ssh-copy-id -i ~/.ssh/id_ed25519_daq.pub daq` (password once)

**nersc** — don't generate a key. `sshproxy` issues a short-lived (~24 h)
key + cert. Install `sshproxy-2.1.2-macos-universal.pkg` (NERSC MFA docs), then
re-run whenever `ssh nersc` starts asking for a password:

```sh
sshproxy -u tens0r        # NERSC password + OTP → ~/.ssh/nersc{,-cert.pub}
```

Hosts not in `config` fall back to ssh's default keys + agent.

## Physics stack (source builds)

`.zshrc` hardcodes these prefixes — build into exactly these paths so PATH,
`CMAKE_PREFIX_PATH`, pkg-config and dyld all line up. ROOT comes from Homebrew.

| project | install prefix |
| --- | --- |
| HDF5 1.14.3 | `~/Documents/HDF5/install-hdf5-1_14_3` |
| Geant4 11.4.0 | `~/Documents/GEANT4/install-v11.4.0` |
| BxDecay0 | `~/Documents/BXDECAY0/install` |
| remage | `~/Documents/REMAGE/install` |
| bacon2Data | `~/Documents/ROOT/bacon2Data` (`bobj/`, `compiled/`) |

## Daily drivers (`.zshrc`)

| command | what it does |
| --- | --- |
| `sanity` | system health check (below) |
| `werb` | brew update + upgrade + autoremove + cleanup + doctor |
| `dds` | detailed `ls` + directory size + entry counts |
| `v` · `jn` | activate `~/venvs/v` · launch jupyter-notebook |
| `r <file.root>` | open a ROOT file in a TBrowser |
| `scpbm <file>` | scp file → `daq:/home/bacon/BaconMonitor/` |
| `scplegend <name> <remote_path>` | pull from nersc into iCloud legend-shifts |
| `scpshifter <period> <run>` | pull that run's monitoring PDFs from nersc |

## sanity

```sh
sanity          # all local checks: shell, symlinks, PATH, brew, python, pipx,
                #   ROOT, Geant4 + datasets, HDF5, BxDecay0, remage, toolchain, ssh
sanity --quick  # skip slow runtime tests (ROOT macro, PyROOT, G4 datasets, brew outdated)
sanity --net    # also test live ssh auth to github / daq / nersc
```

Green across the board (minus any stack you haven't built) = done. Exits 1 on
any failure, so it's scriptable.

## Maintenance

- Edit files **in this repo** — symlinks make changes live; commit + push here,
  `git pull` on the other machine.
- Added/removed a formula? Update `Brewfile`, then re-run
  `brew bundle --file "$REPO/Brewfile"` elsewhere (`brew bundle check` shows drift).
- Run `sanity` after any brew upgrade or stack rebuild.
