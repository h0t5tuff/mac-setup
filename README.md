# mac-setup

My macOS shell environment, version-controlled. Three files live in this repo
and get **symlinked** into place — so any edit here is live immediately, and
every machine stays in sync with `git pull`.

| repo file | symlinked to                       | what it is                                          |
| --------- | ---------------------------------- | --------------------------------------------------- |
| `.zshrc`  | `~/.zshrc`                         | prompt, aliases, Homebrew/Python, physics stack env  |
| `config`  | `~/.ssh/config`                    | SSH defaults + hosts (github, daq, nersc)            |
| `sanity`  | `~/sanity`, `~/.local/bin/sanity`  | full system health check (run it any time)           |

Works on Apple Silicon and Intel — `.zshrc` auto-detects the arch and runs
`arm64` (💻) or `amd64` (🖥️) accordingly.

---

## Setting up a new Mac

### 1. Prerequisites

```sh
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Clone and symlink

```sh
mkdir -p ~/Documents/GitHub ~/.ssh ~/.local/bin
chmod 700 ~/.ssh
cd ~/Documents/GitHub
git clone https://github.com/h0t5tuff/mac-setup.git
REPO=~/Documents/GitHub/mac-setup

# back up real files (not symlinks) if they exist
[ -f ~/.zshrc ]      && [ ! -L ~/.zshrc ]      && mv ~/.zshrc ~/.zshrc.backup
[ -f ~/.ssh/config ] && [ ! -L ~/.ssh/config ] && mv ~/.ssh/config ~/.ssh/config.backup

ln -sfn "$REPO/.zshrc" ~/.zshrc
ln -sfn "$REPO/config" ~/.ssh/config
ln -sfn "$REPO/sanity" ~/sanity
ln -sfn ~/sanity       ~/.local/bin/sanity
chmod +x "$REPO/sanity"
```

### 3. Homebrew packages

The full shared formula set lives in `Brewfile` (top-level packages only —
dependencies follow automatically):

```sh
brew bundle --file "$REPO/Brewfile"
```

The load-bearing ones:

| formula          | why                                                      |
| ---------------- | -------------------------------------------------------- |
| `python@3.14`    | the pinned shell python (`HOMEBREW_PYTHON` in `.zshrc`)   |
| `root`           | CERN ROOT — `r` helper, PyROOT, bacon2Data                |
| `cmake`          | building the physics stack                                |
| `pkgconf` + `gsl`| pkg-config and BxDecay0's GSL dependency                  |
| `qt` + `xerces-c`| Geant4 build/runtime deps (OGLSQt vis driver)             |

### 4. Python tooling

Open a **new terminal first** (so python3 = 3.14 and `PIPX_DEFAULT_PYTHON`
apply), then install the standalone CLI tools:

```sh
pipx install notebook jupyterlab black   # `jn` alias → jupyter-notebook
```

#### Build the main venv

`.zshrc` expects the working venv at `~/venvs/v` (the `v` alias activates it).
Build it, install the scientific stack, and register it as a Jupyter kernel:

```sh
python3 -m venv ~/venvs/v                # python3 = Homebrew 3.14 here;
                                         # otherwise use the explicit path:
                                         # /opt/homebrew/opt/python@3.14/bin/python3.14
source ~/venvs/v/bin/activate            # afterwards just `v`
pip install --upgrade pip
pip install ipykernel numpy matplotlib seaborn pandas scipy
python -m ipykernel install --user \
  --name v \
  --display-name "Python 3.14 (v)"
deactivate
```

The `ipykernel install` step makes the venv show up as **Python 3.14 (v)** in
the kernel picker of the pipx-installed `jupyter-notebook` / `jupyterlab`
(kernels are registered user-wide in `~/Library/Jupyter/kernels/`, so the
notebook server doesn't need to live in the venv).

To rebuild from scratch (e.g. after a Homebrew python major bump), just
`rm -rf ~/venvs/v` and repeat the block above.

### 5. SSH keys

`config` expects one dedicated key per host. Either copy the keys over from
the old Mac (keep perms!) or generate fresh ones and register the new pubkeys:

```sh
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_github
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_daq
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_nersc
chmod 600 ~/.ssh/id_ed25519_*
```

- **github** → GitHub → Settings → SSH and GPG keys → paste `id_ed25519_github.pub`
- **daq** → `ssh-copy-id -i ~/.ssh/id_ed25519_daq.pub daq` (password once)
- **nersc** → follow NERSC's sshproxy/MFA docs for Perlmutter

Hosts *not* listed in `config` fall back to ssh's default keys + agent.

### 6. Physics stack (source builds)

`.zshrc` hardcodes these install prefixes — build each project into exactly
these paths and everything (PATH, `CMAKE_PREFIX_PATH`, pkg-config, dyld) lines
up. `sanity` will tell you what's missing.

| project        | expected install prefix                     |
| -------------- | ------------------------------------------- |
| HDF5 1.14.3    | `~/Documents/HDF5/install-hdf5-1_14_3`      |
| Geant4 11.4.0  | `~/Documents/GEANT4/install-v11.4.0`        |
| BxDecay0       | `~/Documents/BXDECAY0/install`              |
| remage         | `~/Documents/REMAGE/install`                |
| bacon2Data     | `~/Documents/ROOT/bacon2Data` (`bobj/`, `compiled/`) |

(ROOT itself comes from Homebrew, not source.)

### 7. Verify

```sh
exec zsh       # reload the shell
sanity         # full check: shell, symlinks, PATH, brew, python, pipx,
               # ROOT, Geant4 datasets, HDF5, BxDecay0, remage, toolchain, ssh
sanity --net   # also test live ssh auth to github / daq / nersc
sanity --quick # skip the slow runtime tests
```

Green across the board (minus any stack you haven't built yet) = done.
`sanity` exits 1 if anything fails, so it's scriptable too.

---

## Maintenance

- Edit files **in this repo** — symlinks make changes live instantly.
- Commit and push from here; `git pull` on the other machine.
- Installed or removed a brew formula? Update `Brewfile` too, then
  `brew bundle --file "$REPO/Brewfile"` on the other Mac keeps them equal
  (`brew bundle check` shows drift).
- `werb` alias = brew update/upgrade/cleanup/doctor in one go.
- Run `sanity` after any brew upgrade or stack rebuild.
