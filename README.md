# mac-setup

My macOS shell environment, version-controlled. Three files are **symlinked**
into place, so edits here go live instantly
machine.

| repo file | symlinked to                      |
| --------- | --------------------------------- |
| `.zshrc`  | `~/.zshrc`                        |
| `config`  | `~/.ssh/config`                   |
| `sanity`  | `~/sanity`, `~/.local/bin/sanity` |

## Bootstrap

```sh
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

mkdir -p ~/Documents/GitHub ~/.ssh ~/.local/bin && chmod 700 ~/.ssh
cd ~/Documents/GitHub && git clone https://github.com/h0t5tuff/mac-setup.git
REPO=~/Documents/GitHub/mac-setup

# back up real dotfiles, not existing symlinks
[ -f ~/.zshrc ]      && [ ! -L ~/.zshrc ]      && mv ~/.zshrc ~/.zshrc.backup
[ -f ~/.ssh/config ] && [ ! -L ~/.ssh/config ] && mv ~/.ssh/config ~/.ssh/config.backup
ln -sfn "$REPO/.zshrc" ~/.zshrc
ln -sfn "$REPO/config" ~/.ssh/config
ln -sfn "$REPO/sanity" ~/sanity && chmod +x "$REPO/sanity"
ln -sfn ~/sanity       ~/.local/bin/sanity

brew bundle --file "$REPO/Brewfile"

# new terminal (python3 = Homebrew 3.14), then:
pipx install notebook jupyterlab black
pipx inject jupyterlab jupyterlab_widgets && pipx inject notebook jupyterlab_widgets
python3 -m venv ~/venvs/v && source ~/venvs/v/bin/activate
pip install ipykernel ipywidgets numpy matplotlib seaborn pandas scipy \
            awkward hist legend-pydataobj dspeed pylegendmeta dbetto
python -m ipykernel install --user --name v --display-name "Python 3.14 (v)"
deactivate
```

## SSH

`config` sets global defaults (keep-alive, multiplexing, Keychain agent, no
GSSAPI/X11) plus one key per host:

| host         | target                          | key                        |
| ------------ | ------------------------------- | -------------------------- |
| `github.com` | github.com                      | `id_ed25519_github`        |
| `daqTensor`  | 64.106.63.220 · `Tensor`        | `id_ed25519_daqTensor`     |
| `nersc`      | perlmutter.nersc.gov · `tens0r` | `nersc` + `nersc-cert.pub` |

Copy the keys from the old Mac (`chmod 600`) or generate fresh

## Physics stack (source builds)

in `.zshrc` ROOT comes from Homebrew.

| project         | install                                              |
| --------------- | ---------------------------------------------------- |
| HDF5 2.1.0      | `~/Documents/HDF5/install-hdf5_2.1.0`                |
| Geant4 11.4.2   | `~/Documents/GEANT4/install-v11.4.2`                 |
| BxDecay0        | `~/Documents/BXDECAY0/install`                       |
| remage 0.24.0   | `~/Documents/REMAGE/install-remage-v0.24.0`          |
| legend-metadata | `~/Documents/REMAGE/legend-metadata`                 |
| bacon2Data      | `~/Documents/ROOT/bacon2Data` (`bobj/`, `compiled/`) |
