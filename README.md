# Mishal's Arch configuration

This repository backs up curated, portable configuration from `~/.config`.
It intentionally does **not** track browser profiles, caches, D-Bus state,
PulseAudio cookies, Remmina preferences, or other files that may contain
tokens, credentials, or machine-specific state.

## Save configuration changes

```bash
cd ~/.config
git status
git add .gitignore README.md niri eww ghostty swaylock fuzzel systemd \
  pipewire wireplumber xdg-desktop-portal autostart cliphist scripts \
  brave-flags.conf
git commit -m "Describe the configuration change"
git push origin main
```

Check `git diff --cached` before each commit. Do not use `git add -A` or
`git add .` in this directory: application state and secrets should remain
outside the backup.

## Back up selected system configuration

The following files live under `/etc`, so they are not automatically included
in this user-configuration repository. Before a major system change, copy only
the reviewed, non-secret files into `system-backup/` and commit them:

```bash
cd ~/.config
mkdir -p system-backup/etc/{kernel,sysctl.d,modprobe.d,systemd}
sudo install -m 644 /etc/kernel/cmdline system-backup/etc/kernel/cmdline
sudo install -m 644 /etc/sysctl.d/90-desktop-tune.conf system-backup/etc/sysctl.d/90-desktop-tune.conf
sudo install -m 644 /etc/sysctl.d/99-network-performance.conf system-backup/etc/sysctl.d/99-network-performance.conf
sudo install -m 644 /etc/sysctl.d/99-network-tune.conf system-backup/etc/sysctl.d/99-network-tune.conf
sudo install -m 644 /etc/modprobe.d/i915-fbc-psr.conf system-backup/etc/modprobe.d/i915-fbc-psr.conf
git add system-backup
git commit -m "Backup system tuning"
git push origin main
```

Do not commit NetworkManager connection profiles, browser data, keyrings,
cookies, SSH keys, password stores, or files containing API tokens.

## Validate configuration

Run `~/.config/scripts/validate-configs.sh` after edits. It checks shell and
Python syntax, the Niri configuration, systemd user units, and ShellCheck or
Eww when those tools are available.

Clipboard history is limited by `cliphist/config` and is wiped when the Niri
session ends. It can still contain sensitive data during the active session;
run `cliphist wipe` whenever you want to clear it immediately.

The display defaults target `eDP-1` and `HDMI-A-1`. Override projector scripts
with `NIRI_MIRROR_SOURCE` and `NIRI_MIRROR_TARGET` in the service environment
on machines that use different connector names. The `output` block and Eww's
`:monitor` value in the desktop configs remain machine-specific by design.

## Window shortcuts

Regular terminal shortcuts use Ghostty's `+new-window` action, so every press
opens a window. `niri/scripts/niri_spawnjump.py` backs the floating-terminal
and file-manager shortcuts. `--workspace` means only Niri's single focused
workspace; `--active-workspaces` explicitly means the visible workspace on
every output. Launches are serialized per application and workspace to prevent
rapid key repeats from exceeding an instance limit.

The floating-terminal binding is a toggle. When focused, it moves to the next
dynamic workspace without following focus. Invoking the shortcut elsewhere
moves it directly to the uniquely identified focused workspace and focuses it.
No persistent named workspace is created.

The compositor key grammar is intentional: `Alt` launches applications and
system tools, while `Mod` controls windows and workspaces. `Mod+Shift` moves,
`Mod+Ctrl` resizes, and `Mod+Alt` moves one window across workspaces or
monitors. `Alt+Q` and `Mod+V` are retained as muscle-memory exceptions.
