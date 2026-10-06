# mac-setup

My macOS dev environment, version-controlled. These files are **symlinked**
into place, so edits here go live instantly.

| repo file                                | symlinked to                      |
| ---------------------------------------- | --------------------------------- |
| `.zshrc`                                 | `~/.zshrc`                        |
| `config`                                 | `~/.ssh/config`                   |
| `gitconfig`                              | `~/.gitconfig`                    |
| `sanity`                                 | `~/sanity`, `~/.local/bin/sanity` |
| `bin/{remage,remage-cpp,g4,g4build}`     | `~/.local/bin/…`                  |

## What lives where

| layer                                   | source of truth                          |
| --------------------------------------- | ---------------------------------------- |
| Homebrew formulae, casks, VS Code exts  | `Brewfile`                               |
| `~/venvs/v` (Jupyter + LEGEND stack)    | `venvs/v.txt` (exact `pip freeze` lock)  |
| `~/venvs/torrent`                       | `venvs/torrent.txt` + recipe below       |
| pipx apps                               | bootstrap below (`black`)                |
| remage, Geant4 (+ ROOT for own apps)    | `pixi/remage`, `pixi/geant4` (exact lock) |
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
for b in remage remage-cpp g4 g4build; do ln -sfn "$REPO/bin/$b" ~/.local/bin/$b; done

brew bundle --file "$REPO/Brewfile"     # formulae, casks (VS Code, MacTeX), VS Code extensions

# new terminal (python3 = Homebrew 3.14), then:
pipx install black    # standalone CLI tools only — Jupyter lives in the venv

python3 -m venv ~/venvs/v
~/venvs/v/bin/pip install -r "$REPO/venvs/v.txt"
~/venvs/v/bin/python -m ipykernel install --user --name v --display-name "Python 3.14 (v)"
~/venvs/v/bin/playwright install chromium   # headless browser for `nbconvert --to webpdf`

(cd "$REPO/pixi/remage" && pixi install)    # exact envs from pixi.lock (see Physics stack)
(cd "$REPO/pixi/geant4" && pixi install)
```

Then build the torrent venv (below).

### Keeping it reproducible

```sh
brew bundle cleanup --file "$REPO/Brewfile"    # lists installs missing from the Brewfile
~/venvs/v/bin/pip freeze       # compare with venvs/v.txt; refresh it after installing anything
```

## Python versions

**3.14 is the only Python.** It is `HOMEBREW_PYTHON`, backs `~/venvs/v`, and is
what `python3` resolves to. pipx apps and `~/venvs/torrent` are built on it too.
(The pixi environments carry their own conda-forge Python; they're isolated and
never on `PATH` outside `pixi run`/`pixi shell`.) The few packages
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

## Physics stack (pixi)

remage and Geant4 come from conda-forge through two pixi workspaces — no source
builds. Each has `pixi.toml` + an exact `pixi.lock` for `osx-arm64` and `osx-64`;
`.pixi/config.toml` sets `detached-environments = true`, so the environments
(hard-linked packages, ~11 GB shared) live in `~/Library/Caches/rattler`, not iCloud.

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

Projects using it:

| project                       | location                                        | how                              |
| ----------------------------- | ----------------------------------------------- | -------------------------------- |
| LEGEND1000-Simulation         | `~/Documents/LEGEND1000-Simulation`             | `remage`                         |
| geant4-11-tutorial            | `~/Documents/GEANT4/geant4-11-tutorial`         | `g4build`, `g4 ./build-pixi/sim` |
| BACONCalibrationSimulation    | `~/Documents/BACONCalibrationSimulation`        | `g4build`; run from a directory *next to* the repo (`fSTLFileDir` is `../BACONCalibrationSimulation/STLFiles/`) |
| legend-metadata               | `~/Documents/Legend-metadata` (private, legend-exp) | `$LEGEND_METADATA`           |
| bacon2Data                    | `~/Documents/bacon2Data` (liebercanis)          | Homebrew ROOT                    |

Source-build recipes for the old stack live in `~/Documents/Physics-Simulation-Stack-Build-AppleSilicon-and-Linux`.

## Not automated (do by hand)

- **Xcode** (full app, App Store) — the CLT alone is enough for builds.
- **SSH keys** — copy or regenerate; see SSH above.
- **legend-metadata** — private repo; needs LEGEND GitHub access.
- **claude-science** (`~/.local/bin/claude-science`) — installed by its own installer.
