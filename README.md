# Dotfiles

My configuration files, tracked with Git.

## How it works

The files live in `~/dotfiles`. Symlinks let applications find them at their
usual locations.

Each application has its own folder. For example:

```text
~/.tmux.conf -> ~/dotfiles/tmux/.tmux.conf
```

Links are currently created with `ln -s`; no extra tools are needed.

## tmux

Includes `.tmux.conf` and the centered-pane script.

On a new machine, make sure the destination files do not already exist, then link:

```sh
mkdir -p "$HOME/.tmux/scripts"
ln -s "$HOME/dotfiles/tmux/.tmux.conf" "$HOME/.tmux.conf"
ln -s "$HOME/dotfiles/tmux/.tmux/scripts/center-pane.sh" "$HOME/.tmux/scripts/center-pane.sh"
```

The config uses TPM for plugins and `xclip` for clipboard copying. Install TPM
separately at `~/.tmux/plugins/tpm`, then press `Ctrl-a I` in tmux to install
plugins. Plugins and saved sessions stay outside this repo.

## Alacritty

Includes the terminal config and Everforest Dark Soft theme.
Uses JetBrainsMono Nerd Font Mono.

On a new machine, make sure `~/.config/alacritty` does not already exist, then link:

```sh
mkdir -p "$HOME/.config"
ln -s "$HOME/dotfiles/alacritty/.config/alacritty" "$HOME/.config/alacritty"
```

## Ghostty

Includes the terminal config and Everforest Dark Soft theme.
Uses JetBrainsMono Nerd Font Mono.

On a new machine, make sure `~/.config/ghostty` does not already exist, then link:

```sh
mkdir -p "$HOME/.config"
ln -s "$HOME/dotfiles/ghostty" "$HOME/.config/ghostty"
```

## Bash

Includes `.bashrc`, `.bash_aliases`, `.bash_profile`, and `.profile`.
Optional tool setup is loaded only when available. Java and other system tools
use their installed commands instead of hardcoded installation paths.

On a new machine, make sure these files do not already exist in your home, then link:

```sh
ln -s "$HOME/dotfiles/bash/.bashrc" "$HOME/.bashrc"
ln -s "$HOME/dotfiles/bash/.bash_aliases" "$HOME/.bash_aliases"
ln -s "$HOME/dotfiles/bash/.bash_profile" "$HOME/.bash_profile"
ln -s "$HOME/dotfiles/bash/.profile" "$HOME/.profile"
```

The startup files can source `~/.local/bin/env`, `~/.cargo/env`, and
`~/apps/git-subrepo/.rc`. These are not included here and are skipped when missing.

## Git

Includes `.gitconfig` with my name, email, and default branch.

On a new machine, make sure `~/.gitconfig` does not already exist, then link:

```sh
ln -s "$HOME/dotfiles/git/.gitconfig" "$HOME/.gitconfig"
```

## Tridactyl

Includes `tridactylrc` with Firefox keyboard shortcuts.
Requires the Tridactyl extension and its native messenger.

On a new machine, make sure `~/.config/tridactyl` does not already exist, then link:

```sh
mkdir -p "$HOME/.config"
ln -s "$HOME/dotfiles/tridactyl" "$HOME/.config/tridactyl"
```

In Firefox, run `:source` or press `,r` to reload the config.

## OpenCode

Includes the settings, Everforest theme, and conventional commit skill.
Service files, credentials, and session data stay outside this repo.

On a new machine, make sure the destination files do not already exist, then link:

```sh
mkdir -p "$HOME/.config/opencode/themes" "$HOME/.config/opencode/skills/write-git-conventional-commit"
ln -s "$HOME/dotfiles/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"
ln -s "$HOME/dotfiles/opencode/cli.json" "$HOME/.config/opencode/cli.json"
ln -s "$HOME/dotfiles/opencode/themes/everforest-soft.json" "$HOME/.config/opencode/themes/everforest-soft.json"
ln -s "$HOME/dotfiles/opencode/skills/write-git-conventional-commit/SKILL.md" "$HOME/.config/opencode/skills/write-git-conventional-commit/SKILL.md"
```

Link only these files, not the whole OpenCode config directory.

## Neovim

Includes the Lua config, plugin lockfile, and documentation.
The old Git repository was backed up separately; this config now belongs to dotfiles.

On a new machine, make sure `~/.config/nvim` does not already exist, then link:

```sh
mkdir -p "$HOME/.config"
ln -s "$HOME/dotfiles/nvim" "$HOME/.config/nvim"
```

Local history stays ignored. Installed plugins and sessions remain in Neovim's
data and state directories, outside this repo.

The dashboard image lives in `assets/`. Make sure
`~/Pictures/neovim-dashboard-image.png` does not already exist, then link:

```sh
mkdir -p "$HOME/Pictures"
ln -s "$HOME/dotfiles/assets/neovim-dashboard-image.png" "$HOME/Pictures/neovim-dashboard-image.png"
```

See `nvim/ODIN.md` and `nvim/PYTHON_DEBUGGING.md` for tool setup.

## keyd

Includes the keyboard layers, layer OSD script, its user service, and a small
local GNOME extension. The extension uses GNOME's built-in OSD to display NAV,
UTILITY, and MAIN. It supports GNOME 51; future GNOME releases may require
compatibility updates. Custom OSD is not required.

The listener needs `gdbus` and permission to run `keyd listen`.

Make sure the destination files do not already exist, then link the user files:

```sh
mkdir -p "$HOME/.local/bin" "$HOME/.config/systemd/user" "$HOME/.local/share/gnome-shell/extensions"
ln -s "$HOME/dotfiles/keyd/keyd-layer-listener" "$HOME/.local/bin/keyd-layer-listener"
ln -s "$HOME/dotfiles/keyd/keyd-layer-listener.service" "$HOME/.config/systemd/user/keyd-layer-listener.service"
ln -s "$HOME/dotfiles/keyd/keyd-layer-osd@local" "$HOME/.local/share/gnome-shell/extensions/keyd-layer-osd@local"
```

Log out and back in so GNOME discovers the local extension, then enable it:

```sh
gnome-extensions enable keyd-layer-osd@local
```

If the old Custom OSD extension is installed, disable it in Extension Manager.
Preview a layer from the terminal:

```sh
gdbus call --session \
  --dest org.gnome.Shell \
  --object-path /org/gnome/Shell/Extensions/KeydLayerOsd \
  --method org.gnome.Shell.Extensions.KeydLayerOsd.ShowLayer \
  NAV
```

`keyd/default.conf` is a copy, not a symlink. With keyd installed, review it before
installing it as the system config. These commands replace `/etc/keyd/default.conf`
and apply the keyboard mappings:

```sh
sudo install -D -o root -g root -m 0644 "$HOME/dotfiles/keyd/default.conf" /etc/keyd/default.conf
sudo keyd reload
```

On a new machine, start the listener after installing its dependencies:

```sh
systemctl --user daemon-reload
systemctl --user enable --now keyd-layer-listener.service
```

If the listener was already running, restart it to load script changes:

```sh
systemctl --user restart keyd-layer-listener.service
```

Switch between the keyd layouts and confirm their labels appear. Volume and
brightness continue to use GNOME's normal OSD. To inspect listener errors:

```sh
journalctl --user -u keyd-layer-listener.service -n 30 --no-pager
```

Repeat the system config install and reload when changing `keyd/default.conf`.

## Adding configs

Add one application at a time:

1. Choose its config files and check for conflicts.
2. Move them here without changing their contents.
3. Create the symlinks and check that the application still works.
4. Review and commit before adding the next application.

Keep passwords, API keys, installed plugins, and session data out of Git.

## Status

tmux, Alacritty, Ghostty, Bash, Git, Tridactyl, OpenCode,
and Neovim added and linked. keyd's user files are linked; its system config is
tracked as a copy.
Other configs are unchanged.
