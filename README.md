# Mishal's Arch configuration

This repository backs up curated, portable configuration from `~/.config`.
It intentionally does **not** track browser profiles, caches, D-Bus state,
PulseAudio cookies, Remmina preferences, or other files that may contain
tokens, credentials, or machine-specific state.

## Save configuration changes

```bash
cd ~/.config
git status
git add .gitignore README.md niri eww ghostty swaylock fuzzel mako \
  networkmanager-dmenu swayosd systemd pipewire wireplumber \
  xdg-desktop-portal autostart cliphist scripts brave-flags.conf
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
Python syntax, the Niri configuration, systemd user units, Fuzzel, Ghostty,
INI files, and ShellCheck or Eww when those tools are available.

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

The floating-terminal binding is a toggle backed by the persistent tmux session
`floating-terminal`. When focused, the Ghostty window closes while tmux keeps
the shell alive. Invoking the shortcut again reopens Ghostty and attaches the
same session. If its window is already open elsewhere, the shortcut pulls and
focuses it. No hidden or persistent scratchpad workspace is created.

The compositor key grammar is intentional: `Alt` launches applications and
system tools, while `Mod` controls windows and workspaces. `Mod+direction`
focuses, `Mod+Ctrl+direction` moves a tiled item or nudges a floating window,
and `Mod+Shift+direction` focuses a monitor. Add `Ctrl+Shift` to move a column
to another monitor.

Floating windows use Niri's native layer model. `Mod+Space` toggles the focused
window between tiled and floating, and `Mod+grave` switches focus between the
two layers. `Mod+-`/`Mod+=` change width, while adding `Shift` changes height.
`Mod+Shift+C` centers the focused window. With a pointer, `Mod` plus left drag
moves a window and `Mod` plus right drag resizes it.

Application and general shortcuts stay on `Alt`. `Mod+V` remains the Windows
clipboard-history muscle-memory exception, and `Alt+Q` closes the focused
window.

`Mod+F1` opens a compact searchable shortcut guide. Equivalent arrow and
H/J/K/L bindings share rows so the full command set remains accessible on the
1366×768 display without relying on Niri's clipped built-in overlay.
