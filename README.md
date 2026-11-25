# ezsh

A Shell for my Arch + Hyprland setup.

## Running

ezsh lives in `~/.config/quickshell/ezsh`, so Quickshell finds it by name:

```sh
qs -c ezsh                 # start the shell
```

Start it with Hyprland from `hyprland.conf`:

```ini
exec-once = qs -c ezsh
```

## IPC

Every command is `qs -c ezsh ipc call <target> <function> [args...]`. `qs -c ezsh ipc show` lists them from the running shell.

| Target | Function | What it does |
|---|---|---|
| `view` | `open <view>` | Open a view on the focused monitor |
| `view` | `toggle <view>` | Open a view, or close it if it is already open |
| `view` | `openPage <view> <page>` | Open a view on a given page |
| `view` | `togglePage <view> <page>` | Open a view on a page, or close it if that page is already open |
| `view` | `close` | Close the open view |
| `volume` | `increase` / `decrease` | Step the output volume |
| `brightness` | `increase` / `decrease` | Step the screen brightness |
| `media` | `playPause` / `next` / `previous` | Control the player shown on the dashboard |
| `capture` | `screenshot` | Open the screenshot overlay |
| `capture` | `record` | Open the recording overlay, or stop the recording in progress |
| `capture` | `pause` | Pause or resume the recording |
| `capture` | `stop` | Stop the recording |
| `capture` | `cancel` | Close the capture overlay without capturing |

Views and their pages:

| View | Pages |
|---|---|
| `launcher` | `apps` (default), `clipboard`, `symbols` |
| `wallpaper` | none |
| `controlpanel` | `home` (default), `wifi`, `bluetooth`, `nightlight`, `audio`, `battery` |
| `session` | none |

```sh
qs -c ezsh ipc call view toggle launcher
qs -c ezsh ipc call view togglePage launcher clipboard
qs -c ezsh ipc call view openPage controlpanel wifi
qs -c ezsh ipc call volume increase
```

Volume and brightness step sizes come from `Config.services` in `config/Config.qml`.

## Global shortcuts

ezsh registers these Hyprland global shortcuts under the app id `ezsh`. Bind them with `global, ezsh:<name>`:

| Name | What it does |
|---|---|
| `volumeUp` | Raise volume |
| `volumeDown` | Lower volume |
| `brightnessUp` | Raise screen brightness |
| `brightnessDown` | Lower screen brightness |
| `mediaPlayPause` | Play or pause media |
| `mediaNext` | Next track |
| `mediaPrevious` | Previous track |
| `screenshot` | Take a screenshot |
| `record` | Start or stop a screen recording |

Views have no global shortcuts. Bind them through IPC instead.

## Example binds

```ini
# hyprland.conf
bindel = , XF86AudioRaiseVolume, global, ezsh:volumeUp
bindel = , XF86AudioLowerVolume, global, ezsh:volumeDown
bindel = , XF86MonBrightnessUp, global, ezsh:brightnessUp
bindel = , XF86MonBrightnessDown, global, ezsh:brightnessDown
bindl = , XF86AudioPlay, global, ezsh:mediaPlayPause
bindl = , XF86AudioNext, global, ezsh:mediaNext
bindl = , XF86AudioPrev, global, ezsh:mediaPrevious
bind = , Print, global, ezsh:screenshot
bind = SHIFT, Print, global, ezsh:record

bind = SUPER, Space, exec, qs -c ezsh ipc call view toggle launcher
bind = SUPER, V, exec, qs -c ezsh ipc call view togglePage launcher clipboard
bind = SUPER, Period, exec, qs -c ezsh ipc call view togglePage launcher symbols
bind = SUPER, W, exec, qs -c ezsh ipc call view toggle wallpaper
bind = SUPER, A, exec, qs -c ezsh ipc call view toggle controlpanel
bind = SUPER, Escape, exec, qs -c ezsh ipc call view toggle session
```


## Planned Features
1. App Launcher
2. Clipboard
3. Emoji + Nerd Font glyphs
4. Wallpaper Selector
5. Screen Capture
6. Screen Recording
7. Dynamic Theming 
8. Theme Selector
9. Color Picker 
10. Control Panel
11. Configurations
12. Settings
13. Hyprland Config

## Tasks Completed
November 22, 2026
- [x] Border
- [x] Exclusion Zone
- [x] Bar Default/Expanded
- [x] OSD Slider/Messages
- [x] Services
November 23, 2026
- [x] App Launcher (apps, >commands, clipboard, symbols)
- [x] Wallpaper Selector
November 24, 2026
- [x] Control Panel
- [x] Expanded bar 2nd row - media player, compact notifications, and system tray
November 25, 2026
- [x] Screen capture (region/window/screen, annotation editor) and screen recording
