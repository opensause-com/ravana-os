# Ravana desktop: the macOS model

How each macOS mechanism maps to Ravana (KDE Plasma 6 underneath).

## Menu bar (top)

| macOS | Ravana | Status |
|---|---|---|
| Apple menu: About, System Settings, App Store, Force Quit, Sleep, Restart, Shut Down, Lock, Log Out | **Ravana menu** (crown, `org.ravana.menu`) with the same items; Restart / Shut Down / Log Out show a confirmation with a countdown | Done |
| App menu of the focused app | Global menu (`org.kde.plasma.appmenu`); KDE/Qt apps fill it, GTK/Electron apps keep their own menus | Done |
| Status icons (Wi-Fi, sound, battery, Bluetooth) | System tray | Done |
| Spotlight (magnifier, Cmd+Space) | **Ravana Search** button + **Meta+Space**: KRunner centered (apps, files, settings, maths, units, web) | Done |
| Clock with date | `Mon 9 Nov 20:01` | Done |
| Control Center (toggle grid) | Tray popups today; a single Control Center panel | Next |
| Notification Center | Plasma notifications, top-right under the clock | Done |
| Translucent bar | Glass over the wallpaper, solid when a window is maximized | Done |

## Dock (bottom)

| macOS | Ravana | Status |
|---|---|---|
| Floating, centered, sized to its icons | Floating, centered, fit-to-content | Done |
| Launchpad (full-screen app grid) | **Launchpad** first in the dock, also on the **Meta** key | Done |
| Running indicator dots, click to focus/minimize | Task manager indicators | Done |
| Trash at the end, after a divider | Trash after a separator | Done |
| Magnification on hover | Not available in Plasma's dock | Not planned |
| Genie minimize | Magic Lamp | Done |

## Windows

| macOS | Ravana | Status |
|---|---|---|
| Close / minimize / zoom on the left | Buttons on the left | Done |
| Red / yellow / green "traffic lights" | Coloured round buttons | Next (needs a window decoration theme) |
| Mission Control | Overview: Meta+W or four-finger swipe up | Done |
| Spaces | Virtual desktops (Ctrl+Meta+Left/Right) | Done |
| Hot corners | Off by default, like macOS | Done |
| Rounded corners, soft shadows | Breeze shadows; rounded corners need a KWin effect | Later (optional, GPU cost) |

## Power on, power off

| macOS | Ravana | Status |
|---|---|---|
| Boot logo + progress | Plymouth crown animation | Done |
| Login window over the wallpaper | Plasma Login Manager, Ravana wallpaper and clock | Done |
| Login → desktop transition | Ravana splash | Done |
| Restart / Shut Down confirmation with countdown, reopen windows | Plasma logout prompt; previous session restored | Done |
| Sleep from the menu, wake to lock screen | Sleep in the Ravana menu, Ravana lock screen | Done |
| Shutdown screen | Plymouth crown on shutdown too | Done |

## Look

- Dark only: Ravana Dark colours, Ravana wallpaper (light variant removed).
- Inter for UI, JetBrains Mono for code, Papirus icons.
- Installer in Ravana crimson.

## Performance rules

- Only GPU-cheap effects: blur, magic lamp, overview. No wobbly windows.
- No file indexing (Baloo off), no extra background daemons.
- Custom widgets are plain QML with no background services.

## Updates (stability)

- `stable` (`:latest`) rebuilds once a week, after changes have been through `testing`.
- Every update is a whole image: it applies on reboot and can be rolled back from the boot menu.
- Gaming needs current graphics drivers and kernels, so Ravana follows Fedora's release cycle instead of a multi-year frozen base.
