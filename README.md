# niri config

**branches:**
- `main` - niri (current)
- `bspwm` - old setup (archived)

**smart workspace assignments:**
- workspace 1: VS Code (auto-maximized)
- workspace 2: browsers (auto-maximized)  
- workspace 3: communication apps

**system integration:**
- xwayland-satellite for X11 application support  
- XDG desktop portals for file dialogs and screen sharing
- automatic hardware-based feature detection

---

## all the keybindings (yes, ALL of them)

**launch stuff**
- `Alt+Return` `Alt+T` - terminal (kitty)
- `Alt+Shift+Return` `Alt+Shift+T` - floating terminal
- `Mod+Return` `Mod+Space` `Alt+Space` - app launcher (fuzzel)
- `Alt+E` - file manager (nautilus)
- `Mod+V` - clipboard history
- `Super+L` - lock screen
- `Alt+Q` - close window
- `Mod+Shift+Q` - force kill window (emergency)
- `Mod+Shift+E` `Ctrl+Mod+Delete` - quit niri
- `Mod+Shift+Slash` - show this mess (hotkey overlay)
- `Mod+S` - toggle screen reader (orca)

**focus windows (vim keys work)**
- `Mod+H/Left` - focus left
- `Mod+J/Down` - focus down  
- `Mod+K/Up` - focus up
- `Mod+L/Right` - focus right
- `Mod+Home` - first column
- `Mod+End` - last column

**move windows around**
- `Mod+Shift+H/Left` - move left
- `Mod+Shift+J/Down` - move down
- `Mod+Shift+K/Up` - move up
- `Mod+Shift+L/Right` - move right
- `Mod+Ctrl+Home` - move to first
- `Mod+Ctrl+End` - move to last

**workspaces**
- `Mod+1-9` - go to workspace 1-9
- `Mod+Page_Down` - workspace down
- `Mod+Page_Up` - workspace up
- `Alt+Tab` - previous workspace
- `Mod+O` - toggle overview
- `Mod+Ctrl+1-9` - move window to workspace 1-9
- `Mod+Ctrl+Down/Page_Down` - send window down
- `Mod+Ctrl+Up/Page_Up` - send window up
- `Mod+Shift+Page_Down` - move workspace down
- `Mod+Shift+Page_Up` - move workspace up

**resize stuff**
- `Mod+Alt+Left/Right/Up/Down` - resize column/window by 10%

**floating windows**
- `Mod+T` - toggle floating/tiling
- `Ctrl+Alt+Left/Right` - resize floating width by 10%
- `Ctrl+Alt+Up/Down` - resize floating height by 10%

**window layouts**
- `Mod+R` - cycle column widths
- `Mod+Shift+R` - cycle window heights
- `Mod+Ctrl+R` - reset window height
- `Mod+F` - maximize column
- `Mod+Shift+F` - fullscreen
- `Mod+Ctrl+F` - expand to full width
- `Mod+C` - center column
- `Mod+Ctrl+C` - center all visible

**column magic**
- `Mod+,` - consume window into column
- `Mod+.` - expel window from column
- `Mod+W` - toggle tabbed mode

**mouse wheel wizardry**
- `Mod+Scroll↓/↑` - switch workspace
- `Mod+Scroll←/→` - focus column
- `Mod+Ctrl+Scroll↓/↑` - move window to workspace
- `Mod+Ctrl+Scroll←/→` - move column
- `Mod+Shift+Scroll↓/↑` - focus column (alternative)
- `Mod+Ctrl+Shift+Scroll↓/↑` - move column (alternative)

**screenshots**
- `Print` - screenshot
- `Ctrl+Print` - screenshot screen
- `Mod+Print` - screenshot window

**media keys (the ones that actually work)**
- `XF86AudioRaiseVolume` - volume +10%
- `XF86AudioLowerVolume` - volume -10%
- `XF86AudioMute` - mute toggle
- `XF86AudioMicMute` - mic mute
- `XF86MonBrightnessUp` - brightness +10%
- `XF86MonBrightnessDown` - brightness -10%

**wallpaper controls**
- `Mod+B` - cycle to next wallpaper
- `Mod+Shift+B` - cycle to previous wallpaper  
- `Mod+Ctrl+B` - random wallpaper
- `Mod+Alt+B` - preview current wallpaper info

**other weird ones**
- `Mod+Escape` - toggle keyboard shortcuts inhibit (???)
- `Mod+Shift+P` - power off monitors

