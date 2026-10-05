# mac-setup

My macOS dev environment, version-controlled. Four files are **symlinked**
into place, so edits here go live instantly.

| repo file   | symlinked to                      |
| ----------- | --------------------------------- |
| `.zshrc`    | `~/.zshrc`                        |
| `config`    | `~/.ssh/config`                   |
| `gitconfig` | `~/.gitconfig`                    |
| `sanity`    | `~/sanity`, `~/.local/bin/sanity` |

## What lives where

| layer                                   | source of truth                          |
| --------------------------------------- | ---------------------------------------- |
| Homebrew formulae, casks, VS Code exts  | `Brewfile`                               |
| `~/venvs/v` (Jupyter + LEGEND stack)    | `venvs/v.txt` (exact `pip freeze` lock)  |
| `~/venvs/torrent`                       | `venvs/torrent.txt` + recipe below       |
| pipx apps                               | bootstrap below (`black`)                |
| Geant4 / BxDecay0 / remage              | build recipes below                      |
| shell, SSH, git                         | the symlinked files above                |

Run `sanity` after any change — it also flags drift between the machine and
this repo. Apps installed by hand before brew (e.g. VS Code on the original Mac)
count as satisfied when their `.app` is already in `/Applications`; a new Mac
gets them from the Brewfile.

## Bootstrap

```sh
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

mkdir -p ~/Documents ~/.ssh ~/.local/bin && chmod 700 ~/.ssh
cd ~/Documents && git clone https://github.com/h0t5tuff/mac-setup.git
REPO=~/Documents/mac-setup

# back up real dotfiles, not existing symlinks
for f in ~/.zshrc ~/.ssh/config ~/.gitconfig; do [ -f $f ] && [ ! -L $f ] && mv $f $f.backup; done
ln -sfn "$REPO/.zshrc"    ~/.zshrc
ln -sfn "$REPO/config"    ~/.ssh/config
ln -sfn "$REPO/gitconfig" ~/.gitconfig
ln -sfn "$REPO/sanity"    ~/sanity && chmod +x "$REPO/sanity"
ln -sfn ~/sanity          ~/.local/bin/sanity

brew bundle --file "$REPO/Brewfile"     # formulae, casks (VS Code, MacTeX), VS Code extensions

# new terminal (python3 = Homebrew 3.14), then:
pipx install black    # standalone CLI tools only — Jupyter lives in the venv

python3 -m venv ~/venvs/v
~/venvs/v/bin/pip install -r "$REPO/venvs/v.txt"
~/venvs/v/bin/python -m ipykernel install --user --name v --display-name "Python 3.14 (v)"
~/venvs/v/bin/playwright install chromium   # headless browser for `nbconvert --to webpdf`
```

Then build the torrent venv and the physics stack (sections below).

### Keeping it reproducible

```sh
brew bundle cleanup --file "$REPO/Brewfile"    # lists installs missing from the Brewfile
~/venvs/v/bin/pip freeze       # compare with venvs/v.txt; refresh it after installing anything
```

## Python versions

**3.14 is the only Python.** It is `HOMEBREW_PYTHON`, backs `~/venvs/v`, and is
what `python3` resolves to. Everything else is built on it too: remage (v0.26's
bundled `share/remage_venv`), pipx apps, and `~/venvs/torrent`. The few packages
in Homebrew's global site-packages (numpy, tbb, xrootd, cryptography, …) are
installed by brew formulae as dependencies — never `pip install` there.

`~/venvs/torrent` (used by the `torrent` shell function) is the one special case:
PyPI's `libtorrent` ships no 3.14 wheels, so the venv takes its bindings from
Homebrew's `libtorrent-rasterbar` instead — a symlink to
`/opt/homebrew/lib/python3.14/site-packages/libtorrent.cpython-314-darwin.so`
in the venv's site-packages. Rebuild it with:

```sh
python3 -m venv ~/venvs/torrent
ln -s /opt/homebrew/lib/python3.14/site-packages/libtorrent.cpython-314-darwin.so \
      "$(~/venvs/torrent/bin/python -c 'import sysconfig;print(sysconfig.get_paths()["purelib"])')/"
~/venvs/torrent/bin/pip install -r "$REPO/venvs/torrent.txt"
```

## Jupyter lives in the venv

JupyterLab and Notebook are installed **into `~/venvs/v`**, not via pipx or brew.
That was deliberate: the kernel already has `ipywidgets`, so putting the frontend
in the same environment makes `jupyterlab_widgets` resolve by construction. Two
earlier layouts are gone —

- `brew "jupyterlab"` — shadowed the pipx copy (`/opt/homebrew/bin` precedes
  `~/.local/bin` on `PATH`), so the version you ran was never the one you configured.
- `pipx install jupyterlab notebook` + `pipx inject … jupyterlab_widgets` — the
  injects never took, so widgets rendered blank in both frontends.

Launch with `~/venvs/v/bin/jupyter lab`, or `venv` (the `.zshrc` alias for
`source ~/venvs/v/bin/activate`) and then `jupyter lab`. Keep pipx for standalone
CLI tools like `black`, where env isolation is the point.

LEGEND packages install under one name and import under another:
`legend-pygeom-hpges` → `pygeomhpges`, `legend-pygeom-optics` → `pygeomoptics`,
`legend-pygeom-tools` → `pygeomtools`.

## LaTeX (VS Code, replaces Overleaf)

`mactex-no-gui`, `tex-fmt` and the `latex-workshop` extension all come from the
Brewfile. `path_helper` puts `/Library/TeX/texbin` on `PATH`:

```sh
eval "$(/usr/libexec/path_helper)"
pdflatex --version          # confirm texbin is on PATH
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

Copy the keys from the old Mac (`chmod 600`) or generate fresh — private keys
never go in this repo. The CERN key must be registered in the CERN account
portal; lxplus still asks for 2FA from outside CERN.

## Physics stack (source builds)

Built from source and wired up in `.zshrc`; ROOT, HDF5, Qt, Xerces-C and CLHEP
come from the Brewfile.

| project         | source                                         | install                                     |
| --------------- | ---------------------------------------------- | ------------------------------------------- |
| Geant4 11.4.2   | github.com/Geant4/geant4 @ `v11.4.2`           | `~/Documents/GEANT4/install-v11.4.2`        |
| BxDecay0 1.2.1  | github.com/BxCppDev/bxdecay0 @ `9a3cf59`       | `~/Documents/BXDECAY0/install`              |
| remage 0.26.0   | github.com/legend-exp/remage @ `v0.26.0`       | `~/Documents/REMAGE/install-remage-v0.26.0` |
| legend-metadata | github.com/legend-exp/legend-metadata (private) | `~/Documents/Legend-metadata`              |
| bacon2Data      | github.com/liebercanis/bacon2Data              | `~/Documents/bacon2Data` (`bobj/`, `compiled/`) |

Build in this order — each step needs the previous install:

```sh
J=$(sysctl -n hw.ncpu)

# Geant4 — MT, GDML, Qt vis, datasets
cd ~/Documents/GEANT4
git clone --branch v11.4.2 https://github.com/Geant4/geant4.git
cmake -S geant4 -B build-v11.4.2 -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$HOME/Documents/GEANT4/install-v11.4.2 \
  -DGEANT4_BUILD_MULTITHREADED=ON -DGEANT4_INSTALL_DATA=ON \
  -DGEANT4_USE_GDML=ON -DGEANT4_USE_QT=ON -DGEANT4_USE_SYSTEM_EXPAT=ON
  # for remage LH5 output, add: -DGEANT4_USE_HDF5=ON -DHDF5_ROOT=/opt/homebrew/opt/hdf5
cmake --build build-v11.4.2 -j$J --target install

# BxDecay0 — with its Geant4 extension
cd ~/Documents/BXDECAY0
git clone https://github.com/BxCppDev/bxdecay0.git && git -C bxdecay0 checkout 9a3cf59
cmake -S bxdecay0 -B build -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$HOME/Documents/BXDECAY0/install \
  -DCMAKE_PREFIX_PATH="$HOME/Documents/GEANT4/install-v11.4.2;/opt/homebrew/opt/xerces-c;/opt/homebrew" \
  -DBXDECAY0_WITH_GEANT4_EXTENSION=ON -DBXDECAY0_INSTALL_DBD_GA_DATA=ON
cmake --build build -j$J --target install

# remage — ROOT and BxDecay0 support are auto-detected
cd ~/Documents/REMAGE
git clone https://github.com/legend-exp/remage.git && git -C remage checkout v0.26.0
cmake -S remage -B build-remage-v0.26.0 -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$HOME/Documents/REMAGE/install-remage-v0.26.0 \
  -DCMAKE_PREFIX_PATH="$HOME/Documents/GEANT4/install-v11.4.2;$HOME/Documents/BXDECAY0/install;/opt/homebrew/opt/xerces-c;/opt/homebrew"
cmake --build build-remage-v0.26.0 -j$J --target install
remage-cpp --version-rich     # lists ROOT / BxDecay0 / GDML / HDF5 support
```

`RMG_USE_ROOT` / `RMG_USE_BXDECAY0` don't switch features on — support is enabled
whenever the dependency is found; setting the flag `ON` only makes a missing
dependency a hard error instead of a silent skip.

## Not automated (do by hand)

- **Xcode** (full app, App Store) — the CLT alone is enough for builds.
- **SSH keys** — copy or regenerate; see SSH above.
- **legend-metadata** — private repo; needs LEGEND GitHub access.
- **claude-science** (`~/.local/bin/claude-science`) — installed by its own installer.
