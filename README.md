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
  pipewire wireplumber xdg-desktop-portal autostart brave-flags.conf
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
