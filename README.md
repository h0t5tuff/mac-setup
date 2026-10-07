# mac-setup

My macOS dev environment, version-controlled: Homebrew, Python venvs, the pixi physics
stack (remage, Geant4, ROOT), shell, SSH and git. Follow **Set up a new Mac** top to
bottom to rebuild it on another Mac (e.g. the work MacBook).

## Before you start

- **Chip and macOS:** Apple menu → About This Mac. You need **Apple Silicon** (M1 or later)
  and **macOS 14 or newer**. On an Intel Mac, read [Intel Macs](#intel-macs) first.
- **Disk:** ~35 GB free (pixi envs ~20 GB, MacTeX ~10 GB, Homebrew the rest).
- **Admin password:** Homebrew and the MacTeX/XQuartz installers ask for it.
- **From the old Mac**, have these ready (AirDrop or USB stick):
  - SSH private keys from `~/.ssh/`: `id_ed25519_github`, `id_ed25519_cern`,
    `id_ed25519_daqTensor`, `id_ed25519_daqbacon` — only the hosts you need on this Mac.
    For GitHub you can make a fresh key instead (step 7).
  - Optional: VS Code `~/Library/Application Support/Code/User/settings.json`
    (or turn on VS Code Settings Sync).

Budget 1–2 hours, mostly downloads (step 3 and step 6).

## Set up a new Mac

Run everything in Terminal (zsh, the macOS default), in order. Commands in one block can
be pasted together.

### 1. Command-line tools + Homebrew

```sh
xcode-select --install
```

A dialog opens — click Install and wait until it finishes. Then:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Ignore Homebrew's "Next steps" about `~/.zprofile`: this repo's `.zshrc` does that job.

✔ `brew --version` prints a version.

### 2. Clone this repo and link the dotfiles

Any existing `~/.zshrc`, `~/.ssh/config` or `~/.gitconfig` is kept as `*.backup`.

```sh
mkdir -p ~/Documents ~/.ssh ~/.local/bin && chmod 700 ~/.ssh
cd ~/Documents && git clone https://github.com/h0t5tuff/mac-setup.git
REPO=~/Documents/mac-setup
for f in ~/.zshrc ~/.ssh/config ~/.gitconfig; do [ -f $f ] && [ ! -L $f ] && mv $f $f.backup; done
ln -sfn "$REPO/.zshrc"    ~/.zshrc
ln -sfn "$REPO/config"    ~/.ssh/config
ln -sfn "$REPO/gitconfig" ~/.gitconfig
ln -sfn "$REPO/sanity"    ~/sanity
ln -sfn ~/sanity          ~/.local/bin/sanity
for b in remage remage-cpp g4 g4build; do ln -sfn "$REPO/bin/$b" ~/.local/bin/$b; done
```

✔ `ls -l ~/.zshrc` points into `~/Documents/mac-setup`.

### 3. Install everything from Homebrew

```sh
brew bundle --file "$REPO/Brewfile"
```

Formulae (Python 3.14, ROOT, pixi, cmake, …), apps (VS Code, MacTeX, XQuartz) and the VS Code
extensions. Takes a while (MacTeX is several GB) and asks for your password once or twice.

✔ `brew bundle check --file "$REPO/Brewfile"` says `The Brewfile's dependencies are satisfied.`

### 4. Open a new terminal window

The new window loads `.zshrc`: Homebrew, Python 3.14 and ROOT get set up. **Run all
remaining steps in this new window.**

```sh
REPO=~/Documents/mac-setup
pipx install black
```

✔ `which python3` → `/opt/homebrew/opt/python@3.14/…` and `root-config --version` prints a version.

### 5. Python venvs

`~/venvs/v` holds Jupyter and the LEGEND/analysis stack:

```sh
PY=/opt/homebrew/opt/python@3.14/bin/python3.14
$PY -m venv ~/venvs/v
~/venvs/v/bin/pip install -r "$REPO/venvs/v.txt"
~/venvs/v/bin/python -m ipykernel install --user --name v --display-name "Python 3.14 (v)"
~/venvs/v/bin/playwright install chromium
```

`~/venvs/torrent` gets libtorrent from Homebrew, linked in by hand:

```sh
$PY -m venv ~/venvs/torrent
ln -s /opt/homebrew/lib/python3.14/site-packages/libtorrent.cpython-314-darwin.so \
      "$(~/venvs/torrent/bin/python -c 'import sysconfig;print(sysconfig.get_paths()["purelib"])')/"
~/venvs/torrent/bin/pip install -r "$REPO/venvs/torrent.txt"
```

✔ `jl` opens JupyterLab with a **Python 3.14 (v)** kernel.

### 6. Physics stack (pixi)

```sh
(cd "$REPO/pixi/remage" && pixi install --locked)
(cd "$REPO/pixi/geant4" && pixi install --locked)
```

`--locked` installs exactly what `pixi.lock` lists (Geant4 datasets included) and stops if the
lock doesn't match `pixi.toml`.

✔ `remage --help` prints usage, and `g4 geant4-config --version` prints `11.4.3`.

### 7. SSH keys

Move the keys you brought into `~/.ssh/` and lock down their permissions. AirDrop puts them in
`~/Downloads`; change the path if they're somewhere else.

```sh
mv ~/Downloads/id_ed25519_* ~/.ssh/
chmod 600 ~/.ssh/id_ed25519_*
```

Or, for GitHub only, make a fresh key and add it to your account:

```sh
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_github
pbcopy < ~/.ssh/id_ed25519_github.pub
```

Then paste it at github.com → Settings → SSH and GPG keys → New SSH key.

```sh
ssh -T git@github.com
```

Answer `yes` to the host-key question. If the key has a passphrase, it's asked once and then
kept in the Keychain.

✔ `Hi h0t5tuff! You've successfully authenticated…`

NERSC and CERN need extra steps. See the [SSH](#ssh) section.

### 8. Clone and build the projects

```sh
cd ~/Documents
git clone https://github.com/h0t5tuff/LEGEND1000-Simulation.git
git clone --recurse-submodules git@github.com:legend-exp/legend-metadata.git Legend-metadata
git clone -b runTwo https://github.com/liebercanis/bacon2Data.git
git clone https://github.com/aleder/BACONCalibrationSimulation.git
mkdir -p GEANT4 && git clone https://github.com/MustafaSchmidt/geant4-11-tutorial.git GEANT4/geant4-11-tutorial
```

`legend-metadata` is private (LEGEND GitHub access) and its submodules come over SSH, so it
needs step 7.

**bacon2Data** is built against Homebrew ROOT. Run `make clean` first: the repo carries
x86_64 `.o`/`.so` files that `make` would otherwise treat as up to date. Afterwards `git status`
shows them as modified, which is expected.

```sh
cd ~/Documents/bacon2Data
ln -sfn /opt/homebrew/opt/root/etc/root/Makefile.arch bobj/Makefile.arch
make -C bobj clean && make -C bobj
make -C compiled clean && make -C compiled
```

The **Geant4 apps** are built against `pixi/geant4`:

```sh
cd ~/Documents/BACONCalibrationSimulation && g4build
cd ~/Documents/GEANT4/geant4-11-tutorial && g4build
```

✔ `file ~/Documents/bacon2Data/bobj/libBaconAna.so` says `arm64`, and each Geant4 app has a `build-pixi/` folder.

### 9. Check

```sh
sanity
```

On the old Mac this is all ✅. On a new Mac, expect only these:

- ❌ `key missing` for SSH keys you didn't copy — fine if you don't need that host.
- ⚠️ for projects you didn't clone.

## Keeping it reproducible

After installing or upgrading anything, update the matching file here and commit:

| changed                       | update                                                                            |
| ----------------------------- | --------------------------------------------------------------------------------- |
| brew formula / cask / VS Code extension | add it to `Brewfile`; `brew bundle cleanup --file "$REPO/Brewfile"` lists strays |
| `~/venvs/v` packages          | `~/venvs/v/bin/pip freeze > venvs/v.txt`, then re-add the two header lines         |
| `~/venvs/torrent` packages    | `~/venvs/torrent/bin/pip freeze > venvs/torrent.txt`, then re-add the header line  |
| pixi packages                 | edit `pixi/<ws>/pixi.toml`, run `pixi install` there — it rewrites `pixi.lock`     |

`sanity`'s *Reproducible from repo* section reports Brewfile and venv drift. The pixi envs
can't drift: `pixi run` always syncs them to `pixi.lock`.

## What lives where

| repo file                                | symlinked to                      |
| ---------------------------------------- | --------------------------------- |
| `.zshrc`                                 | `~/.zshrc`                        |
| `config`                                 | `~/.ssh/config`                   |
| `gitconfig`                              | `~/.gitconfig`                    |
| `sanity`                                 | `~/sanity`, `~/.local/bin/sanity` |
| `bin/{remage,remage-cpp,g4,g4build}`     | `~/.local/bin/…`                  |

Symlinked means edits in this repo go live instantly.

| layer                                   | source of truth                           |
| --------------------------------------- | ----------------------------------------- |
| Homebrew formulae, casks, VS Code exts  | `Brewfile`                                |
| `~/venvs/v` (Jupyter + LEGEND stack)    | `venvs/v.txt` (exact `pip freeze` lock)   |
| `~/venvs/torrent`                       | `venvs/torrent.txt` + step 5              |
| pipx apps                               | step 4 (`black`)                          |
| remage, Geant4 (+ ROOT for own apps)    | `pixi/remage`, `pixi/geant4` (exact lock) |
| shell, SSH, git                         | the symlinked files above                 |
| physics projects                        | step 8                                    |

VS Code installed by hand before brew counts as satisfied when its `.app` is already in
`/Applications`; a new Mac gets it from the Brewfile.

## Python

**3.14 is the only Python.** It is `HOMEBREW_PYTHON`, backs `~/venvs/v`, and is
what `python3` resolves to. pipx apps and `~/venvs/torrent` are built on it too.
(The pixi environments carry their own conda-forge Python; they're isolated and
never on `PATH` outside `pixi run`/`pixi shell`.) The few packages
in Homebrew's global site-packages (numpy, tbb, xrootd, cryptography, …) are
installed by brew formulae as dependencies — never `pip install` there.

- **`~/venvs/torrent`** (used by the `torrent` shell function): PyPI's `libtorrent` has no
  3.14 wheels, so the venv uses Homebrew's `libtorrent-rasterbar` bindings via the symlink in step 5.
- **`pyg4ometry`** (in `~/venvs/v`): its macOS wheel links Homebrew's **OpenCASCADE 7.9**
  (`libTK*.7.9.dylib`) at runtime. If brew moves OpenCASCADE to a new minor version, CAD import
  breaks until pyg4ometry ships a matching wheel. Check with
  `~/venvs/v/bin/python -c "import pyg4ometry.pyoce"`.

### Jupyter lives in the venv

JupyterLab and Notebook are installed **into `~/venvs/v`**, not via pipx or brew. The kernel
already has `ipywidgets`, so putting the frontend in the same environment makes
`jupyterlab_widgets` resolve by construction. Two earlier layouts are gone —

- `brew "jupyterlab"` — shadowed the pipx copy (`/opt/homebrew/bin` precedes
  `~/.local/bin` on `PATH`), so the version you ran was never the one you configured.
- `pipx install jupyterlab notebook` + `pipx inject … jupyterlab_widgets` — the
  injects never took, so widgets rendered blank in both frontends.

Launch with `jl` / `jn` (`.zshrc` aliases for `~/venvs/v/bin/jupyter lab|notebook`), or
`venv` (activates `~/venvs/v`) and then `jupyter lab`. Keep pipx for standalone CLI tools
like `black`, where env isolation is the point.

LEGEND packages install under one name and import under another:
`legend-pygeom-hpges` → `pygeomhpges`, `legend-pygeom-optics` → `pygeomoptics`,
`legend-pygeom-tools` → `pygeomtools`.

## LaTeX (VS Code, replaces Overleaf)

`mactex-no-gui`, `tex-fmt` and the `latex-workshop` extension all come from the
Brewfile. A new terminal has `/Library/TeX/texbin` on `PATH` (via `path_helper`):

```sh
pdflatex --version
```

## SSH

`config` sets global defaults (keep-alive, multiplexing, Keychain agent, no
GSSAPI/X11) plus one key per host:

| host         | target                          | key                        |
| ------------ | ------------------------------- | -------------------------- |
| `github.com` | github.com                      | `id_ed25519_github`        |
| `daqTensor`  | 64.106.63.220 · `Tensor`        | `id_ed25519_daqTensor`     |
| `daqbacon`   | 64.106.63.220 · `bacon`         | `id_ed25519_daqbacon`      |
| `nersc`      | perlmutter.nersc.gov · `tens0r` | `nersc` + `nersc-cert.pub` |
| `cern`       | lxplus.cern.ch · `melmikaw`     | `id_ed25519_cern`          |

Private keys never go in this repo. Keys need `chmod 600`; `~/.ssh` needs `700`.

- **CERN:** a fresh key must be registered in the CERN account portal. lxplus still asks for
  2FA from outside CERN.
- **NERSC:** don't copy this key. It's a 24-hour certificate from `sshproxy.sh` (download it
  from the NERSC docs, *Connecting → MFA*). Run `sshproxy.sh -u tens0r` (password + OTP), which
  writes `~/.ssh/nersc` and `nersc-cert.pub`. Repeat it when the certificate expires.
- `sanity --net` tests the github, daq and nersc connections.

## Physics stack (pixi)

remage and Geant4 come from conda-forge through two pixi workspaces — no source
builds. Each has `pixi.toml` + an exact `pixi.lock` for Apple Silicon and Intel;
`.pixi/config.toml` sets `detached-environments = true`, so the environments
live in `~/Library/Caches/rattler`, not in `~/Documents` (iCloud).

| workspace     | contents                                                                                     | commands               |
| ------------- | -------------------------------------------------------------------------------------------- | ---------------------- |
| `pixi/remage` | remage 1.1.0 (Geant4 11.3.2 MT, GDML, BxDecay0, **HDF5/LH5**) + `legend-pygeom-{tools,hpges,optics}` | `remage`, `remage-cpp` |
| `pixi/geant4` | Geant4 11.4.3 **Qt** build, ROOT 6.40.04, cmake, compilers, expat headers — for your own apps | `g4`, `g4build`        |

The commands are `pixi run` wrappers (`bin/`, symlinked into `~/.local/bin`), so
activation (Geant4 data paths) is automatic and they work from bash scripts too.

```sh
remage -t 8 -m -g geom.gdml -o out.lh5 -- run.mac   # -m merges per-thread LH5 files; ROOT is merged anyway
remage-cpp --version-rich                          # "ROOT CERN no" is fine: it only silences ROOT's stack traces
g4build                                            # configure + build ./ into build-pixi/ against pixi/geant4
g4 ./build-pixi/sim run.mac                        # run it inside the env
```

Pitfalls, all handled here:

- `remage` exits **2** when warnings were printed — add `--ignore-warnings` where a script checks the exit code.
- conda-forge ships Geant4 11.4.3 as `noqt_*` (headless) and `qt_*`; the manifest pins `qt_*`, which
  needs macOS ≥ 14 — declared on the platform entries (`mac-arm64`, `mac-intel`).
- `expat` is listed explicitly: Geant4's CMake config needs its headers; without them CMake picks the
  macOS SDK's older expat and fails.
- `g4build` puts `$CONDA_PREFIX` first on `CMAKE_PREFIX_PATH`, so the env's ROOT/Geant4 win over
  Homebrew's — one C++ runtime per binary.
- `.zshrc` skips its PATH reset inside `pixi shell` (`$PIXI_IN_SHELL`), so the env's tools stay first there.
- Homebrew ROOT's `thisroot.sh` (sourced by `.zshrc`) exports `PYTHONPATH`, `ROOTSYS`, `CMAKE_PREFIX_PATH`, …;
  left alone, `import ROOT` inside `pixi/geant4` loads *Homebrew's* ROOT. The `bin/` wrappers and
  `pixi shell` (via `.zshrc`) clear them, so each env sees only its own ROOT.

## Projects

All in `~/Documents`, cloned and built in step 8:

| project                       | repo                                         | built / run with                 |
| ----------------------------- | -------------------------------------------- | -------------------------------- |
| LEGEND1000-Simulation         | `h0t5tuff/LEGEND1000-Simulation`             | `remage`                         |
| Legend-metadata               | `legend-exp/legend-metadata` (private)       | read via `$LEGEND_METADATA`      |
| bacon2Data (branch `runTwo`)  | `liebercanis/bacon2Data`                     | Homebrew ROOT; `make` in `bobj/`, then `compiled/` |
| BACONCalibrationSimulation    | `aleder/BACONCalibrationSimulation`          | `g4build`; run from a directory *next to* the repo (`fSTLFileDir` is `../BACONCalibrationSimulation/STLFiles/`) |
| geant4-11-tutorial            | `MustafaSchmidt/geant4-11-tutorial` (in `GEANT4/`) | `g4build`, `g4 ./build-pixi/sim` |

`.zshrc` exports `BACONHOME`, `BOBJ`, `COMPILED`, `ROOTDATA`, `CAENDATA` and
`LEGEND_METADATA` for these paths. Source-build recipes for the old (pre-pixi)
stack: `h0t5tuff/Physics-Simulation-Stack`.

## Not automated (do by hand)

- **SSH keys** — step 7 and [SSH](#ssh).
- **VS Code settings** — not in this repo; Settings Sync, or copy `settings.json` (see *Before you start*).
- **Xcode** (full app, App Store) — only if you need it; the command-line tools are enough for builds.
- **claude-science** (`~/.local/bin/claude-science`) — installed by its own installer.
- **`torrent`** — the script it runs lives in personal iCloud Drive (`MechaTronics/T/torrent_dl.py`),
  so it only works on a Mac signed into that iCloud account.

## Intel Macs

The Brewfile and both `pixi.lock`s work on Intel. `.zshrc` is the gap: its `amd64()`
only loads Homebrew, and `HOMEBREW_PYTHON` (`/opt/homebrew/opt/python@3.14`) and the ROOT setup
are Apple Silicon paths. On Intel, Homebrew lives in `/usr/local`, so:

- change those paths in `.zshrc` to `/usr/local/...`;
- use `/usr/local/bin/brew` in step 1 and `/usr/local/opt/python@3.14/bin/python3.14` in step 5;
- use `/usr/local/lib/python3.14/...` for the torrent symlink and `/usr/local/opt/root/...` for bacon2Data.
