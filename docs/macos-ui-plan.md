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
| Genie minimize | Ravana's own **Ember** minimize instead (shrink and fade into the dock icon) | Done |

## Windows

| macOS | Ravana | Status |
|---|---|---|
| Close / minimize / zoom on the left | Buttons on the left | Done |
| Red / yellow / green "traffic lights" | Ravana window frame (`tools/gen-window-decoration.py`): dark rounded title bar, coloured round buttons, glyphs on hover | Done |
| Mission Control | Overview: Ctrl+Up or four-finger swipe up | Done |
| Spaces | Virtual desktops (Ctrl+Meta+Left/Right) | Done |
| Hot corners | Off by default, like macOS | Done |
| Rounded corners, soft shadows | Rounded title bar and soft shadow; rounded bottom corners need a KWin effect | Later (optional, GPU cost) |

## Keyboard: ⌘ Cmd = Windows key

Only Windows-key combinations change; Ctrl and Alt behave as usual (Windows habits and games keep working).
Turn off with `sudo systemctl disable --now keyd`.

| Shortcut | Does |
|---|---|
| ⌘C ⌘V ⌘X ⌘Z ⇧⌘Z | Copy, paste (terminals too), cut, undo, redo |
| ⌘A ⌘S ⌘F ⌘G ⌘P ⌘O ⌘N ⌘T ⌘W ⌘Q | Select all, save, find, find next, print, open, new, new tab, close, quit |
| ⌘R ⌘L ⌘D ⌘J ⌘, | Reload, address bar, bookmark, downloads, preferences |
| ⌘1…⌘9, ⇧⌘[ ⇧⌘] | Go to tab, previous/next tab |
| ⌘[ ⌘] | Back, forward |
| ⌘← ⌘→ ⌘↑ ⌘↓ (add ⇧ to select) | Line start/end, document start/end |
| ⌘+ ⌘- ⌘0 | Zoom in, out, reset |
| ⌘Space | Spotlight search |
| ⌘Tab, ⇧⌘Tab | Switch apps |
| ⌘` | Switch windows of the current app |
| ⌘H, ⌘M | Hide, minimize |
| ⌃⌘F | Full screen |
| ⌥⌘Esc | Force quit (click a window) |
| ⌃⌘Q, ⇧⌘Q | Lock screen, log out |
| ⇧⌘3, ⇧⌘4, ⇧⌘5 | Screenshot: full screen, area, screenshot tool |
| ⌃⌘Space or ⌘. | Emoji picker |
| ⌥⌘Space | New file manager window |
| ⌃↑, ⌃↓ | Mission Control, app windows |
| ⌃⌘← ⌃⌘→ | Previous/next desktop (Space) |
| ⌥⌘← ⌥⌘→ ⌥⌘↑ | Tile left/right, maximize |
| Windows key alone | Launchpad |

## Files (Finder → Dolphin)

- Sidebar with favourites and devices, icon view at 64 px, double-click to open, no zoom slider or path text.
- Menus in the top bar, toolbar with back/forward, view modes, search.
- Not available yet: spacebar Quick Look (Dolphin's information panel, F11, shows previews).

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

- Ravana's own crown, wallpaper, icons and fonts; Apple's logo, SF fonts and icons are Apple property and are not used.
- Translucent menu bar, dock, menus (82 % opaque, blurred), Spotlight and Launchpad.
- Dark only: Ravana Dark colours, Ravana wallpaper (light variant removed).
- Inter for UI, JetBrains Mono for code, Papirus icons.
- Installer in Ravana crimson.

## Motion: Ravana's own

The look follows macOS; the motion is Ravana's:

- **Rise** (open/close): windows rise into place from 95 % with a fast ease-out and sink away on close
- **Ember** (minimize): windows shrink and fade into their dock icon on a smooth S-curve, no genie warp
- **Pulse** (dock): a launching app breathes gently with a red ember dot, instead of bouncing
- Boot crown animation, login splash, hover lift in the dock

## Performance rules

- Only GPU-cheap effects: blur, magic lamp, overview. No wobbly windows.
- No file indexing (Baloo off). The only added service is keyd (a few hundred KB of RAM).
- Custom widgets are plain QML with no background services.

## Updates (stability)

- `stable` (`:latest`) rebuilds once a week, after changes have been through `testing`.
- Every update is a whole image: it applies on reboot and can be rolled back from the boot menu.
- Gaming needs current graphics drivers and kernels, so Ravana follows Fedora's release cycle instead of a multi-year frozen base.
