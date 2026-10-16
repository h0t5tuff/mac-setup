# mac-setup

My macOS dev environment, shared by the home and work MacBooks: shell, Homebrew, Python, the pixi
physics stack (remage, Geant4, ROOT), SSH, git and Claude Code. The Python packages and the physics
stack are pinned to exact versions; Homebrew installs whatever is current.

- [Use it](#use-it): every command, with examples
- [Set up a new Mac](#set-up-a-new-mac): step by step
- [Keep it reproducible](#keep-it-reproducible): what to update after installing anything
- [Notes](#notes): why some things are the way they are

## What's where

`~/Documents` syncs through iCloud, so this repo, the projects and `claude-shared` appear on both Macs
by themselves. Everything else in the table is installed separately on each Mac (see the setup steps).

| what | lives in | defined by |
| --- | --- | --- |
| zsh config | `~/.zshrc` → symlink to `.zshrc` here | `.zshrc` |
| SSH hosts | `~/.ssh/config` → symlink to `config` here | `config` (keys: copied by hand) |
| git identity | `~/.gitconfig` → symlink to `gitconfig` here | `gitconfig` |
| health check | `~/.local/bin/sanity` → `sanity` here | `sanity` |
| Homebrew formulae, apps, VS Code extensions | `/opt/homebrew`, `/Applications` | `Brewfile` |
| Python venv `v` (Jupyter, LEGEND, analysis) | `~/venvs/v` | `venvs/v.txt` (exact versions) |
| `torrent` script | `~/Documents/T/` (iCloud) | `.zshrc` runs it |
| remage | `~/Library/Caches/rattler` | `pixi/remage/` (exact lock) |
| Geant4 + ROOT for your own apps | `~/Library/Caches/rattler` | `pixi/geant4/` (exact lock) |
| `remage`, `remage-cpp`, `g4`, `g4build` | `~/.local/bin` → `bin/` here | `bin/` |
| Claude Code instructions + memory | `~/Documents/claude-shared` (iCloud) | step 9 |

Edits to the symlinked files are live immediately, on both Macs.

---

## Use it

### Everyday commands

| command | what it does |
| --- | --- |
| `sanity` | checks the whole setup; `--quick` skips the slow tests, `--net` also tests SSH logins |
| `werb` | Homebrew maintenance: update, upgrade, autoremove, cleanup, doctor |
| `jl` / `jn` | JupyterLab / Jupyter Notebook from `~/venvs/v` |
| `venv` | activate `~/venvs/v` in this shell (`deactivate` to leave) |
| `r file.root` | open a ROOT file in a TBrowser |
| `torrent "magnet:…"` | download a torrent to `~/Downloads` (see [Torrents](#torrents)) |
| `dds` / `dss` | long listing, oldest first; `dss` adds folder size and entry counts |

### Torrents

`torrent` downloads magnet links or `.torrent` files into `~/Downloads`, shows live progress, and exits
when everything is complete.

```sh
torrent "magnet:?xt=urn:btih:..."                     # always quote magnets (zsh treats ? as a wildcard)
torrent ~/Downloads/file.torrent
torrent "magnet:?xt=..." "magnet:?xt=..."             # several at once, one progress line each
torrent --sequential "magnet:?xt=..."                 # pieces in order: start watching a video early
torrent --proxy socks5://host:1080 "magnet:?xt=..."   # route all traffic through a SOCKS5 proxy
```

| option | effect |
| --- | --- |
| `--sequential` | download pieces in order instead of rarest-first |
| `--seed-time S` | keep uploading for `S` seconds after finishing (default 0: stop immediately) |
| `--proxy socks5://[user:pass@]host:port` | all peer, tracker and DNS traffic through the proxy; stops instead of leaking if the proxy drops |
| `--no-dht` | trackers only, no DHT (magnets then need a working tracker) |

- **Progress line:** name, %, done/total, download and upload speed, peers, ETA, state.
- **Stop:** `Ctrl-C`. Partial files stay in `~/Downloads`. Rerun the same command to resume: it rechecks
  what's there and fetches only the rest.
- **Privacy:** without `--proxy`, other peers see your IP address; that's how BitTorrent works. The
  defaults only cut extra exposure: random port, encrypted connections only, no router port mapping
  (UPnP/NAT-PMP), no LAN broadcast.
- **Where it lives:** the script and its notes are in `~/Documents/T/`. It runs on Homebrew's own
  `python3`, because that's the Python Homebrew builds libtorrent for.

### Physics: remage and Geant4

Both run inside pixi environments. The commands below handle activation, so they work from any folder
and from bash scripts.

**remage** (1.1.0: Geant4 11.3.2, multithreaded, GDML, BxDecay0, LH5 and ROOT output):

```sh
remage -t 8 -m -g geom.gdml -o out.lh5 -- run.mac   # 8 threads; -m merges the per-thread output files
remage -t 8 -w -g geom.gdml -o out.root -- run.mac  # -w overwrites an existing output file
remage-cpp --version-rich                           # build details of the engine
```

`remage` exits with code 2 when it printed warnings. In scripts that check the exit code, add
`--ignore-warnings`.

**Your own Geant4 apps** (Geant4 11.4.3 with the Qt viewer, ROOT 6.40.04, cmake, compilers):

```sh
cd ~/Documents/BACONCalibrationSimulation
g4build                                  # configure + build . into build-pixi/
g4build . build-pixi -DSOME_OPTION=ON    # extra cmake options need both folders given first
g4 ./build-pixi/<app>                    # run it (opens the Qt viewer if the app uses one)
g4 ./build-pixi/<app> run.mac            # run a macro in batch
g4 root -l out.root                      # any command inside the env: root, python, geant4-config, …
```

For an interactive shell inside the env: `pixi shell --manifest-path ~/Documents/mac-setup/pixi/geant4/pixi.toml`
(`exit` to leave).

LEGEND metadata: `$LEGEND_METADATA` → `~/Documents/legend-exp/Legend-metadata` (pylegendmeta) and
`$LEGEND1000_METADATA` → `~/Documents/legend-exp/legend1000-metadata` (LEGEND1000-Simulation's `sim/hit.py`).

**Geant4 examples** aren't included in the conda package. Fetch the ones matching 11.4.3 when needed:

```sh
git clone --depth 1 --branch v11.4.3 --filter=blob:none --sparse https://github.com/Geant4/geant4.git ~/Downloads/geant4-v11.4.3
git -C ~/Downloads/geant4-v11.4.3 sparse-checkout set examples
cd ~/Downloads/geant4-v11.4.3/examples/basic/B1 && g4build && g4 ./build-pixi/exampleB1 exampleB1.in
```

### Python and Jupyter

- **Python 3.14** (Homebrew `python@3.14`) is your Python: `python3`, `~/venvs/v` and pipx all use it.
- **Homebrew's default Python** (currently 3.15, `/opt/homebrew/bin/python3`) is the one Homebrew builds
  ROOT's and libtorrent's Python bindings for. So `import ROOT` works with `/opt/homebrew/bin/python3`,
  or with `g4 python` (the pixi env's own ROOT), but not in plain `python3` or `~/venvs/v`.
- **`~/venvs/v`** has Jupyter plus the LEGEND and analysis packages. In Jupyter or VS Code, pick the
  kernel **Python 3.14 (v)**. Install into it with `~/venvs/v/bin/pip install …`, then refresh the lock
  (see [Keep it reproducible](#keep-it-reproducible)).
- **pipx** is only for standalone command-line tools (currently `black`): `pipx install <tool>`.
- Never `pip install` into Homebrew's Python itself.
- LEGEND packages import under different names: `legend-pygeom-hpges` → `pygeomhpges`,
  `legend-pygeom-optics` → `pygeomoptics`, `legend-pygeom-tools` → `pygeomtools`.
- Export a notebook to PDF: `~/venvs/v/bin/jupyter nbconvert --to webpdf notebook.ipynb`.

### SSH and file transfer

| host | connects to | key |
| --- | --- | --- |
| `ssh github.com` | GitHub (account h0t5tuff) | `~/.ssh/id_ed25519_github` |
| `ssh daqTensor` | DAQ machine 64.106.63.220 as `Tensor` | `~/.ssh/id_ed25519_daqTensor` |
| `ssh daqbacon` | DAQ machine as `bacon` | `~/.ssh/id_ed25519_daqbacon` |
| `ssh nersc` | Perlmutter as `tens0r` | `~/.ssh/nersc` + `nersc-cert.pub` (24-hour certificate) |
| `ssh cern` | lxplus as `melmikaw` (asks for 2FA from outside CERN) | `~/.ssh/id_ed25519_cern` |

Connections are reused for 12 hours, so after the first login (and 2FA) further `ssh`/`scp` to the same
host are instant.

- **NERSC certificate:** expires daily. Renew with NERSC's `sshproxy.sh -u tens0r` (password + OTP;
  download the script from the NERSC docs, *Connecting → MFA*). It writes `~/.ssh/nersc` and `nersc-cert.pub`.

| command | copies |
| --- | --- |
| `scpbm file` | `file` → `daqTensor:/home/bacon/BaconMonitor/` |
| `scpdaq /path/on/daq/file.root` | that file from the DAQ to the current folder (makes it readable first, asks for sudo there) |
| `scpdaqposts` | all `post-*.root` from the DAQ's `bacon2Data/compiled` to the current folder |
| `scpdqcpdfs <period> <run>` | LEGEND data-monitor PDFs from NERSC → iCloud `0νββ/legend shifts/<period>_<run>` |
| `scppng <dir>` | all PNGs in NERSC `…/Tensor/shifter/<dir>` → iCloud `Downloads/<dir>` |

### LaTeX

Write in VS Code with the LaTeX Workshop extension: saving builds the PDF, and `tex-fmt` formats the
source. MacTeX provides `pdflatex`, `latexmk` and the rest in `/Library/TeX/texbin`.

### Claude Code

Claude's global instructions (`~/Documents/claude-shared/CLAUDE.md`) and its memory
(`~/Documents/claude-shared/memory/`, one pool for all projects) live in iCloud, so both Macs see the
same ones. Each Mac's `~/.claude` stays local (chat history, sessions) and only points at the shared
folder (step 9).

---

## Set up a new Mac

You need **Apple Silicon** and **macOS 14 or newer** (Apple menu → About This Mac; for Intel see
[Notes](#intel-macs)), ~35 GB free, and your admin password. Budget 1–2 hours, mostly downloads.
From the old Mac, bring the SSH private keys you need (AirDrop or USB stick).

Run each block in Terminal, in order. Each step ends with a ✔ check.

### 1. Command-line tools and Homebrew

```sh
xcode-select --install
```

Click Install in the dialog and wait for it to finish. Then:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Skip Homebrew's "Next steps": this repo's `.zshrc` takes care of them.

✔ `brew --version` prints a version.

### 2. This repo and the dotfile links

With iCloud Desktop & Documents sync on, wait until `~/Documents/mac-setup` has downloaded. Without
it, clone the repo instead:

```sh
mkdir -p ~/Documents && git clone https://github.com/h0t5tuff/mac-setup.git ~/Documents/mac-setup
```

Then link the dotfiles. Any existing real `~/.zshrc`, `~/.ssh/config` or `~/.gitconfig` is kept as `*.backup`.

```sh
REPO=~/Documents/mac-setup
mkdir -p ~/.ssh ~/.local/bin && chmod 700 ~/.ssh
for f in ~/.zshrc ~/.ssh/config ~/.gitconfig; do [ -f $f ] && [ ! -L $f ] && mv $f $f.backup; done
ln -sfn "$REPO/.zshrc"    ~/.zshrc
ln -sfn "$REPO/config"    ~/.ssh/config
ln -sfn "$REPO/gitconfig" ~/.gitconfig
ln -sfn "$REPO/sanity"    ~/sanity
ln -sfn ~/sanity          ~/.local/bin/sanity
for b in remage remage-cpp g4 g4build; do ln -sfn "$REPO/bin/$b" ~/.local/bin/$b; done
```

In Finder, right-click `~/Documents/mac-setup` → **Keep Downloaded**, so iCloud never offloads it.

✔ `ls -l ~/.zshrc` points into `~/Documents/mac-setup`.

### 3. Everything from Homebrew

```sh
brew bundle --file "$REPO/Brewfile"
```

Installs the formulae (Python 3.14, ROOT, pixi, cmake, ffmpeg, …), the apps (VS Code, MacTeX, XQuartz)
and the VS Code extensions. It asks for your password once or twice.

✔ `brew bundle check --file "$REPO/Brewfile"` says `The Brewfile's dependencies are satisfied.`

### 4. Open a new terminal window

The new window loads `.zshrc` (Homebrew, Python 3.14, ROOT). **Do every remaining step in it.**

```sh
REPO=~/Documents/mac-setup
pipx install black
```

✔ `which python3` starts with `/opt/homebrew/opt/python@3.14/`, `root-config --version` prints a version,
and `torrent --help` prints its options.

### 5. Python venv

`~/venvs/v`, with exact package versions from the lock file:

```sh
PY=/opt/homebrew/opt/python@3.14/bin/python3.14
$PY -m venv ~/venvs/v
~/venvs/v/bin/pip install -r "$REPO/venvs/v.txt"
~/venvs/v/bin/python -m ipykernel install --user --name v --display-name "Python 3.14 (v)"
~/venvs/v/bin/playwright install chromium
```

✔ `jl` opens JupyterLab with a **Python 3.14 (v)** kernel.

### 6. Physics stack (pixi)

```sh
(cd "$REPO/pixi/remage" && pixi install --locked)
(cd "$REPO/pixi/geant4" && pixi install --locked)
```

`--locked` installs exactly what `pixi.lock` lists, Geant4 data included, and refuses if the lock is out of date.

✔ `remage --help` prints usage, and `g4 geant4-config --version` prints `11.4.3`.

### 7. SSH keys

Move the keys you brought into `~/.ssh` and restrict them. AirDrop puts them in `~/Downloads`:

```sh
mv ~/Downloads/id_ed25519_* ~/.ssh/
chmod 600 ~/.ssh/id_ed25519_*
```

Or, for GitHub, make a new key and add it at github.com → Settings → SSH and GPG keys → New SSH key:

```sh
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_github
pbcopy < ~/.ssh/id_ed25519_github.pub
```

Test it, and answer `yes` to the host-key question. A key's passphrase is asked once, then kept in the Keychain:

```sh
ssh -T git@github.com
```

For NERSC, don't copy the key: renew it with `sshproxy.sh` (see [SSH](#ssh-and-file-transfer)). A new
CERN key must be registered in the CERN account portal.

✔ `Hi h0t5tuff! You've successfully authenticated…`

### 8. Projects

With iCloud sync, the projects are already in `~/Documents`. Without it, clone them. `legend-metadata`
is private and needs the GitHub key from step 7.

```sh
cd ~/Documents
git clone https://github.com/h0t5tuff/LEGEND1000-Simulation.git
git clone -b runTwo https://github.com/liebercanis/bacon2Data.git
git clone https://github.com/aleder/BACONCalibrationSimulation.git
mkdir -p legend-exp && cd legend-exp
git clone --recurse-submodules git@github.com:legend-exp/legend-metadata.git Legend-metadata
git clone https://github.com/legend-exp/legend1000-metadata.git
git clone https://github.com/legend-exp/legend-simflow.git
git clone https://github.com/legend-exp/optmapper.git
```

Build bacon2Data (against Homebrew ROOT) and BACONCalibrationSimulation (against pixi Geant4). Run
`make clean` first: the bacon2Data repo contains old Intel build files that `make` would otherwise reuse.

```sh
cd ~/Documents/bacon2Data
ln -sfn /opt/homebrew/opt/root/etc/root/Makefile.arch bobj/Makefile.arch
make -C bobj clean && make -C bobj
make -C compiled clean && make -C compiled
cd ~/Documents/BACONCalibrationSimulation && g4build
```

✔ `file ~/Documents/bacon2Data/bobj/libBaconAna.so` says `arm64`.

### 9. Claude Code

Install the Claude desktop app from claude.ai/download, then point it at the shared instructions and memory:

```sh
mkdir -p ~/.claude
printf '{\n  "autoMemoryDirectory": "~/Documents/claude-shared/memory"\n}\n' > ~/.claude/settings.json
echo '@~/Documents/claude-shared/CLAUDE.md' > ~/.claude/CLAUDE.md
```

If `~/.claude/settings.json` already exists, add the `autoMemoryDirectory` line to it instead. In Finder,
right-click `~/Documents/claude-shared` → **Keep Downloaded**.

✔ In a new Claude Code session, "where is your memory directory?" names `~/Documents/claude-shared/memory`.

### 10. Check

```sh
sanity
```

Everything should be ✅, except ❌ `key missing` for SSH keys you chose not to copy.

---

## Keep it reproducible

After installing or upgrading anything, record it here, then run `sanity`. Its *Reproducible from repo*
section flags anything installed that the repo doesn't know about.

| you changed | record it with |
| --- | --- |
| a Homebrew formula, app or VS Code extension | add a line to `Brewfile`; `brew bundle cleanup --file Brewfile` lists anything installed but not listed |
| packages in `~/venvs/v` | `~/venvs/v/bin/pip freeze > venvs/v.txt`, then put back the two `#` header lines |
| a pixi package | edit `pixi/<name>/pixi.toml`, run `pixi install` in that folder (it rewrites `pixi.lock`) |

After `werb`:

- **ROOT upgraded:** rebuild bacon2Data (step 8); its binaries record ROOT's versioned path. Upgrade
  both Macs together, because the rebuilt binaries are shared through iCloud.
- **Homebrew moved to a new default Python** (as 3.14 → 3.15 in October 2026): PyROOT and `torrent`
  follow it automatically. Your `python3`, `~/venvs/v` and pipx stay on 3.14 until you move them
  yourself, which needs every package in `v.txt` to have wheels for the new version.

---

## Notes

**Python.** `python3`, `~/venvs/v` and pipx share one pinned Python (3.14), so they stay compatible when
Homebrew changes its default. Jupyter is installed inside `~/venvs/v`, not with pipx or brew, so the
notebook frontend and the kernel share one `ipywidgets` install; the earlier split setups left widgets
blank. The pixi environments carry their own Python and stay invisible outside `pixi run`/`pixi shell`.

**torrent** runs on Homebrew's default `python3`, which already has Homebrew's libtorrent bindings.
That needs no venv and survives Homebrew's Python upgrades. The previous `~/venvs/torrent` linked in the
bindings for one Python version and broke when Homebrew moved to 3.15.

**pyg4ometry** (CAD import in `~/venvs/v`) links Homebrew's OpenCASCADE 7.9 at runtime. If an upgrade
moves OpenCASCADE to a new version, CAD import breaks until pyg4ometry catches up; check with
`~/venvs/v/bin/python -c "import pyg4ometry.pyoce"`.

**pixi.** The environments live in `~/Library/Caches/rattler`, outside iCloud (`detached-environments`
in each `.pixi/config.toml`). The details the setup depends on:

- remage 1.1 pins Geant4 11.3.2; your own apps get 11.4.3 from the separate `pixi/geant4` workspace.
- `pixi/geant4` pins the Qt build of Geant4 (`qt_*`). It needs macOS 14, declared on the platform entries.
- `expat` is listed in `pixi/geant4` because Geant4's CMake config needs its headers; without it CMake
  picks up the macOS SDK's older expat and fails.
- `g4build` puts the env first on `CMAKE_PREFIX_PATH`, so its ROOT and Geant4 win over Homebrew's.
- Homebrew ROOT's `thisroot.sh` (loaded by `.zshrc`) exports `PYTHONPATH`, `ROOTSYS` and friends, which
  would make the pixi env load Homebrew's ROOT. The `bin/` wrappers and `pixi shell` clear them.
- `.zshrc` skips its PATH reset inside `pixi shell` (`$PIXI_IN_SHELL`), so the env's tools stay first.

**iCloud.** Git repos in `~/Documents` sometimes get iCloud conflict copies named `X 2` (for example
`btbSim 2` after a rebuild). They are safe to delete. Large rebuildable things (venvs, pixi envs,
Homebrew) are deliberately kept out of iCloud.

**Not automated** (by hand on each Mac): SSH keys, VS Code settings (Settings Sync or copy
`~/Library/Application Support/Code/User/settings.json`), the full Xcode app (only if needed),
claude-science (own installer).

### Intel Macs

The Brewfile and both pixi locks work on Intel. Homebrew lives in `/usr/local` there, so change the
`/opt/homebrew` paths in `.zshrc` (`HOMEBREW_PYTHON` and the ROOT setup in `arm64()`) and in steps 1, 5 and 8.
On Intel, `.zshrc`'s `amd64()` doesn't set up Python or ROOT at all, so that needs adding too.
