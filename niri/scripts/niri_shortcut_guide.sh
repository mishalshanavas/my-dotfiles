#!/usr/bin/env bash

set -euo pipefail

# Searchable, compact guide. Equivalent arrow and H/J/K/L bindings share a
# row so every function remains reachable on the laptop display.
guide=$(cat <<'EOF'
APPS      Alt+Space                 Application launcher
APPS      Alt+T                     New terminal
APPS      Alt+Enter                 New terminal
APPS      Alt+Super+T               New floating terminal
APPS      Alt+Shift+Enter           Toggle floating terminal
APPS      Alt+E                     File manager
APPS      Super+V                   Clipboard history
SYSTEM    Alt+L                     Lock screen
SYSTEM    Alt+B                     Next wallpaper
SYSTEM    Alt+S                     Toggle screen reader
SYSTEM    Alt+Q                     Close focused window
SYSTEM    Super+Shift+Q             Force-kill focused window
SYSTEM    Volume / mic / brightness keys  Adjust hardware
WINDOW    Super+Space               Toggle tiled/floating
WINDOW    Super+`                   Switch tiled/floating focus
WINDOW    Super+Arrow / H J K L     Focus window
WINDOW    Super+Ctrl+Arrow / H J K L  Move tile or nudge float
WINDOW    Super+Home / End          Focus first/last column
WINDOW    Super+Ctrl+Home / End     Move column to first/last
WINDOW    Super+- / Super+=         Decrease/increase width
WINDOW    Super+Shift+- / +=        Decrease/increase height
WINDOW    Super+Shift+C             Center window
WINDOW    Super+C                   Center column
WINDOW    Super+Ctrl+C              Center visible columns
WINDOW    Super+F                   Maximize window
WINDOW    Super+M                   Maximize column
WINDOW    Super+Shift+F             Toggle fullscreen
WINDOW    Super+Ctrl+F              Expand column to available width
WINDOW    Super+R / Super+Shift+R   Cycle column width
WINDOW    Super+Ctrl+R              Reset window height
WINDOW    Super+Alt+R               Cycle window height
WINDOW    Super+W                   Toggle tabbed column
WINDOW    Super+, / Super+.         Consume / expel window
WINDOW    Super+[ / Super+]         Consume or expel left/right
WINDOW    Super+O                   Toggle overview
WINDOW    Super+left drag           Move window
WINDOW    Super+right drag          Resize window
WORKSPACE Super+1..9                Focus workspace
WORKSPACE Super+Ctrl+1..9           Move column to workspace
WORKSPACE Super+Alt+1..9            Move window to workspace
WORKSPACE Super+Tab / Shift+Tab     Cycle workspaces
WORKSPACE Super+Alt+Tab             Previous workspace
WORKSPACE Super+Alt+Shift+Tab       Next workspace
WORKSPACE Super+PageUp/PageDown     Focus workspace up/down
WORKSPACE Super+Ctrl+PageUp/Down    Move column to workspace
WORKSPACE Super+Alt+PageUp/Down     Move window to workspace
WORKSPACE Super+Shift+PageUp/Down   Move workspace up/down
WORKSPACE Super+wheel               Focus workspace
WORKSPACE Super+Ctrl+wheel          Move column to workspace
WINDOW    Super+horizontal wheel    Focus left/right
WINDOW    Super+Ctrl+horizontal wheel  Move column left/right
WINDOW    Super+Shift+vertical wheel  Focus left/right
WINDOW    Super+Ctrl+Shift+vertical wheel  Move column left/right
MONITOR   Super+Shift+Arrow / H J K L  Focus monitor
MONITOR   Super+Ctrl+Shift+Arrow    Move column to monitor
MONITOR   Super+Alt+Ctrl+Arrow      Move window to monitor
CAPTURE   Print                     Area screenshot
CAPTURE   Ctrl+Print                Screen screenshot
CAPTURE   Super+Print               Window screenshot
CAPTURE   Super+Shift+Print         Toggle screen recording
CAPTURE   Alt+Shift+O               OCR selected area
CAST      Super+S                   Cast focused window
CAST      Super+Shift+S             Cast focused monitor
CAST      Super+Ctrl+S              Clear cast target
DISPLAY   Alt+P / Alt+Ctrl+P        Start/stop projector mirror
SYSTEM    Alt+Shift+,               Reload Niri config
SYSTEM    Alt+Shift+P               Power off monitors
SYSTEM    Alt+Shift+E               Exit Niri
SYSTEM    Ctrl+Alt+Delete           Exit Niri
SYSTEM    Super+Escape              Toggle shortcut inhibitor
EOF
)

selection=$(printf '%s\n' "$guide" | fuzzel --dmenu --only-match \
    --prompt='Shortcuts > ' --lines=24 --width=68) || exit 0

# Fuzzel returns the clicked/accepted row. Dispatch the real command directly;
# virtual key injection is intentionally ignored by Niri for compositor binds.
shortcut=$(awk '{ print $2 }' <<<"$selection")

# Rows which summarize several directional or numbered bindings need a small
# follow-up picker because there is no single honest action for "Arrow" or 1..9.
case "$shortcut" in
    Super+Arrow|Super+Ctrl+Arrow|Super+Shift+Arrow|Super+Ctrl+Shift+Arrow)
        direction=$(printf '%s\n' Left Down Up Right | fuzzel --dmenu --only-match \
            --prompt='Direction > ' --lines=4 --width=24) || exit 0
        shortcut=${shortcut/Arrow/$direction}
        ;;
    Super+Alt+Ctrl+Arrow)
        direction=$(printf '%s\n' Left Right | fuzzel --dmenu --only-match \
            --prompt='Direction > ' --lines=2 --width=24) || exit 0
        shortcut=${shortcut/Arrow/$direction}
        ;;
    Super+1..9|Super+Ctrl+1..9|Super+Alt+1..9)
        number=$(printf '%s\n' {1..9} | fuzzel --dmenu --only-match \
            --prompt='Workspace > ' --lines=9 --width=24) || exit 0
        shortcut=${shortcut/1..9/$number}
        ;;
    Volume)
        shortcut=$(printf '%s\n' \
            XF86AudioRaiseVolume XF86AudioLowerVolume XF86AudioMute \
            XF86AudioMicMute XF86MonBrightnessUp XF86MonBrightnessDown |
            fuzzel --dmenu --only-match --prompt='Hardware key > ' \
                --lines=6 --width=32) || exit 0
        ;;
    Super+wheel|Super+Ctrl+wheel|Super+horizontal|Super+Ctrl+horizontal|Super+Shift+vertical|Super+Ctrl+Shift+vertical|Super+left|Super+right)
        notify-send 'Shortcut Guide' 'This entry documents a mouse gesture; use the shown gesture.'
        exit 0
        ;;
esac

# Pick the first key where a row documents equivalent aliases or two opposite
# actions. Those rows remain concise; clicking runs the binding shown first.
shortcut=${shortcut%%/*}
cfg=${XDG_CONFIG_HOME:-$HOME/.config}
action() { niri msg action "$@"; }

case "$shortcut" in
    Alt+Space) python3 "$cfg/niri/scripts/niri_app_menu.py" ;;
    Alt+T) ghostty +new-window >/dev/null 2>&1 || exec ghostty ;;
    Alt+Super+T) ghostty --class=com.mishal.FloatingTerminal --gtk-single-instance=false ;;
    Alt+Enter) ghostty +new-window >/dev/null 2>&1 || exec ghostty ;;
    Alt+Shift+Enter) python3 "$cfg/niri/scripts/niri_spawnjump.py" 'ghostty --class=com.mishal.FloatingTerminal -e tmux new-session -A -s floating-terminal' com.mishal.FloatingTerminal --toggle-close ;;
    Alt+E) python3 "$cfg/niri/scripts/niri_spawnjump.py" nautilus ;;
    Super+V) selected=$(cliphist list | fuzzel --dmenu); [[ -z $selected ]] || printf '%s\n' "$selected" | cliphist decode | wl-copy ;;
    Alt+L) "$cfg/swaylock/lock.sh" ;;
    Alt+B) "$cfg/niri/scripts/swaybg_helper.sh" --cycle -d ;;
    Alt+S) if systemctl --user is-active --quiet niri-orca.service; then systemctl --user stop niri-orca.service; else systemctl --user start niri-orca.service; fi ;;
    Alt+Q) action close-window ;;
    Super+Shift+Q) "$cfg/niri/scripts/niri_force_kill_focused.sh" ;;
    XF86AudioRaiseVolume) swayosd-client --output-volume raise --max-volume 100 ;;
    XF86AudioLowerVolume) swayosd-client --output-volume lower --max-volume 100 ;;
    XF86AudioMute) swayosd-client --output-volume mute-toggle --max-volume 100 ;;
    XF86AudioMicMute) swayosd-client --input-volume mute-toggle ;;
    XF86MonBrightnessUp) swayosd-client --brightness raise ;;
    XF86MonBrightnessDown) swayosd-client --brightness lower ;;
    Super+Space) action toggle-window-floating ;;
    'Super+`') action switch-focus-between-floating-and-tiling ;;
    Super+Left) action focus-column-left ;;
    Super+Down) action focus-window-down ;;
    Super+Up) action focus-window-up ;;
    Super+Right) action focus-column-right ;;
    Super+Ctrl+Left) "$cfg/niri/scripts/niri_move_focused.sh" left ;;
    Super+Ctrl+Down) "$cfg/niri/scripts/niri_move_focused.sh" down ;;
    Super+Ctrl+Up) "$cfg/niri/scripts/niri_move_focused.sh" up ;;
    Super+Ctrl+Right) "$cfg/niri/scripts/niri_move_focused.sh" right ;;
    Super+Home) action focus-column-first ;;
    Super+Ctrl+Home) action move-column-to-first ;;
    Super+-) action set-window-width '-10%' ;;
    Super+Shift+-) action set-window-height '-10%' ;;
    Super+Shift+C) action center-window ;;
    Super+C) action center-column ;;
    Super+Ctrl+C) action center-visible-columns ;;
    Super+F) action maximize-window-to-edges ;;
    Super+M) action maximize-column ;;
    Super+Shift+F) action fullscreen-window ;;
    Super+Ctrl+F) action expand-column-to-available-width ;;
    Super+R) action switch-preset-column-width ;;
    Super+Ctrl+R) action reset-window-height ;;
    Super+Alt+R) action switch-preset-window-height ;;
    Super+W) action toggle-column-tabbed-display ;;
    Super+,) action consume-window-into-column ;;
    'Super+[') action consume-or-expel-window-left ;;
    Super+O) action toggle-overview ;;
    Super+Tab) python3 "$cfg/niri/scripts/niri_cycle_workspace.py" next ;;
    Super+Alt+Tab) action focus-workspace-previous ;;
    Super+Alt+Shift+Tab) action focus-workspace-down ;;
    Super+PageUp) "$cfg/niri/scripts/niri_overview_bind.sh" move-workspace-up focus-workspace-up ;;
    Super+Ctrl+PageUp) action move-column-to-workspace-up ;;
    Super+Alt+PageUp) action move-window-to-workspace-up ;;
    Super+Shift+PageUp) action move-workspace-up ;;
    Super+[1-9]) action focus-workspace "${shortcut#Super+}" ;;
    Super+Ctrl+[1-9]) action move-column-to-workspace "${shortcut#Super+Ctrl+}" ;;
    Super+Alt+[1-9]) action move-window-to-workspace "${shortcut#Super+Alt+}" ;;
    Super+Shift+Left) action focus-monitor-left ;;
    Super+Shift+Down) action focus-monitor-down ;;
    Super+Shift+Up) action focus-monitor-up ;;
    Super+Shift+Right) action focus-monitor-right ;;
    Super+Ctrl+Shift+Left) action move-column-to-monitor-left ;;
    Super+Ctrl+Shift+Down) action move-column-to-monitor-down ;;
    Super+Ctrl+Shift+Up) action move-column-to-monitor-up ;;
    Super+Ctrl+Shift+Right) action move-column-to-monitor-right ;;
    Super+Alt+Ctrl+Left) action move-window-to-monitor-left ;;
    Super+Alt+Ctrl+Right) action move-window-to-monitor-right ;;
    Print) action screenshot ;;
    Ctrl+Print) action screenshot-screen ;;
    Super+Print) action screenshot-window ;;
    Super+Shift+Print) "$cfg/niri/scripts/screen-record-toggle.sh" ;;
    Alt+Shift+O) "$cfg/niri/scripts/ocr.sh" ;;
    Super+S) action set-dynamic-cast-window ;;
    Super+Shift+S) action set-dynamic-cast-monitor ;;
    Super+Ctrl+S) action clear-dynamic-cast-target ;;
    Alt+P) systemctl --user start niri-projector-mirror.service ;;
    Alt+Shift+,) action load-config-file ;;
    Alt+Shift+P) action power-off-monitors ;;
    Alt+Shift+E|Ctrl+Alt+Delete) action quit ;;
    Super+Escape) action toggle-keyboard-shortcuts-inhibit ;;
    *) notify-send 'Shortcut Guide' "No click action is defined for $shortcut" ;;
esac
