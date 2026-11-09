# Ravana Shell: design spec and 6-phase plan

Goal: a desktop that looks and feels like current macOS (macOS 26 "Liquid Glass"),
in Ravana's own design and identity, drawn entirely by Ravana Shell on the Ravana UI kit.
KWin stays underneath as the window engine; nothing of Plasma's shell is visible.

Not used: Apple's logo, SF fonts, icons, wallpapers or sounds (Apple's property).
Ravana uses its crown, Inter, Colloid-based icons, its own wallpapers and the Ghanta.

---

## 1. Design language: "Ravana Glass"

### Materials
| Material | Use | Recipe |
|---|---|---|
| **Clear glass** | menu bar | fully transparent; text and icons get a soft shadow for legibility |
| **Regular glass** | dock, Spotlight, Control Center, menus, notifications | blurred backdrop + vibrancy (saturation up) + tint (dark 26 %, light 55 %) + 1 px light rim + top sheen |
| **Thick glass** | sheets, alerts, Settings sidebar | as regular, tint 70 %, stronger shadow |
| **Shadow** | anything floating | 30 px blur, 10 px down, 45 % black (dark) / 20 % (light) |

### Shape (Apple's three rules)
- **Concentric:** inner radius = outer radius − padding (a control inside a card inside a window lines up perfectly).
- **Capsule:** search fields, segmented controls, sliders, toggles, buttons: radius = height ÷ 2.
- **Fixed:** windows 18 px squircle; cards 16; menus 12; menu highlights 7; tooltips 8.

### Type (Inter, Ravana's SF stand-in)
| Role | Size / weight |
|---|---|
| Menu bar, menus, body | 13 / regular (app name 13 / bold) |
| Secondary, captions | 11 / regular, 55 % opacity |
| Section titles | 13 / semibold |
| Large titles (Settings pages, Spotlight) | 22–26 / semibold |
| Clock on lock screen | 96 / light |

### Colour
- Accent **Ravana red #D21F3C** where macOS uses blue (selection, toggles, focus).
- Light and dark token sets; everything follows the system appearance (and Auto by time of day).

### Icons
- **Every app icon renders at the same size on the same squircle grid** (Apple's consistency).
- Icons that aren't square (old/odd app icons) are placed on a neutral squircle plate so the Dock,
  Apps view and Spotlight look uniform.
- Symbols (menu bar, Control Center): one stroke weight, 16 px grid, monochrome.

### Motion (Ravana's own)
- Springs, not linear easing: response ~0.35 s, gentle damping (no wobble).
- **Rise** (windows open/close), **Ember** (minimize), **Pulse** (launching app), glass panels
  scale from 96 % + fade in 220 ms.

---

## 2. Components (spec)

| Component | Spec |
|---|---|
| **Menu bar** | Clear glass, 28 px. Left: crown menu · **bold app name** · app menus (File, Edit…). Right: battery · Wi-Fi · Control Center · Spotlight · `Wed 1 Apr  9:41 AM`. Click-and-slide between menus like macOS. |
| **Ravana menu** | About · System Settings · App Store · Software Update · Recent Items · Force Quit · Sleep · Restart · Shut Down · Lock · Log Out. 12 px radius, red highlight pill. |
| **App menus** | The focused app's real menus read over D-Bus (global menu) and drawn as Ravana menus. |
| **Dock** | Regular glass, 22 px radius, 8 px from the bottom. Icons 52 px, magnify to 84 px (cosine falloff). 4 px dot under open apps. Divider, then Downloads stack and Trash. Name bubble on hover. Right-click: Options (Keep in Dock, Open at Login, Show in Files), Quit. Auto-hide and size in Settings. |
| **Spotlight** (Search or Ask) | Capsule 640 × 52, top third of the screen, regular glass. Results as one list: Top Hit, Apps, Files, Settings, Calculator, Web. **⌘1 = Apps view**. Powered by KRunner's search engine. |
| **Apps view** (Launchpad) | Blurred wallpaper, capsule search "Search Applications" at the top, 7 × 5 grid of 88 px icons, page dots, swipe/scroll between pages, folders, drag to Dock. Dock stays visible. |
| **Control Center** | Grouped glass modules: Wi-Fi · Bluetooth · Hotspot (round bubbles, red when on) · Focus · Appearance · Screen Mirroring · Display slider · Sound slider (+ output device) · Now Playing · Battery. Each module expands for details (Wi-Fi networks list, Bluetooth devices). |
| **Notification Center** | Right-side panel: today's widgets (calendar, weather, battery, now playing) + notifications grouped by app. Opens from the clock or a two-finger swipe from the right edge. |
| **Notifications** | Glass cards top-right, app icon + title + text, actions on hover, grouped stacks, slide away. |
| **HUDs** | Volume / brightness / keyboard light: small glass capsule top-right with a level bar. |
| **App switcher (⌘Tab)** | Glass bar centre-screen, large icons, red ring on the selected app. |
| **Mission Control** | Windows spread with titles, spaces strip at the top (KWin Overview, Ravana-styled). |
| **Windows** | Traffic lights 12 px at 14 px inset, 8 px apart; centred 13 px semibold title; 18 px squircle corners; title bar the same colour as the toolbar. |
| **Sheets & alerts** | Centred, 18 px radius, thick glass, parent window dimmed. |
| **Lock screen** | Wallpaper blurred, big clock, date, avatar, capsule password field, Sleep / Restart / Shut Down. |
| **Login screen** | Same design as the lock screen with user switching. |
| **Setup Assistant** | First boot: language → Wi-Fi → account → appearance → privacy → "Welcome to Ravana". |
| **Ravana Settings** | Floating inset sidebar with search, icons on coloured squircles; content as grouped inset rows (toggles, pop-ups, sliders). Covers Wi-Fi, Bluetooth, Network, Notifications, Sound, Focus, Screen Time-like, General, Appearance, Control Center, Desktop & Dock, Displays, Wallpaper, Lock Screen, Users, Passwords, Keyboard, Trackpad, Mouse, Game settings, Software Update. Advanced: opens the matching KDE page. |

---

## 3. Gestures (trackpad)

Through the InputActions KWin plugin (custom gestures on Wayland), built against the image's KWin.

| Gesture | Action |
|---|---|
| 3-finger swipe up | Mission Control |
| 3-finger swipe up twice / 4-finger pinch in | Apps view |
| 3-finger swipe down | App Exposé (this app's windows) |
| 3-finger swipe left / right | previous / next desktop (Space) |
| 4-finger spread | show desktop |
| 2-finger swipe in from the right edge | Notification Center |
| 2-finger swipe left / right | back / forward in apps (browser, Files) |
| 2-finger scroll, pinch | scroll, zoom (apps) |
| Tap to click, 2-finger tap | click, right-click |

Keyboard (already in place): ⌘Space Spotlight, ⌘Tab apps, ⌘\` windows, ⌃↑ Mission Control,
⇧⌘3/4/5 screenshots, ⌃⌘Q lock, F4 Apps view.

---

## 4. Plan: 6 phases

Each phase ships to the `ravana-shell` preview, is checked with the cloud screenshot test
(every component opened over IPC and captured), then on real hardware.

| Phase | Delivers | Done when |
|---|---|---|
| **1. Foundation** | UI kit v2: materials (clear/regular/thick glass), concentric shapes, type scale, light + dark tokens, spring motion, squircle icon renderer. Notification server so no notification is lost. | Every surface uses only UI-kit parts; light and dark both render correctly |
| **2. Menu bar, Dock, Spotlight, Apps view** | Clear-glass menu bar with app menus (global menu), status icons; final Dock (magnification, stacks, menus, settings); Spotlight capsule with results; Apps view with pages and folders | Screens match the spec side by side with the references |
| **3. Control Center, Notification Center, HUDs** | All modules with expanded views; Notification Center with widgets; notification banners; volume/brightness HUDs | Toggles and sliders work on hardware; notifications from apps appear and group |
| **4. Gestures and window experience** | InputActions plugin and the gesture table; ⌘Tab switcher; Mission Control styling; window chrome polish | All gestures work on a real trackpad; switcher and Mission Control match the spec |
| **5. Lock, login, power, sheets, Setup Assistant** | Ravana lock and login screens, shutdown/restart dialogs, sheet styling, first-boot Setup Assistant | A fresh install goes from boot to desktop through only Ravana screens |
| **6. Ravana Settings, app polish, switch-over** | Ravana Settings app; app styling pass (GTK, Qt, Chrome, Firefox, Steam); appearance locked; Ravana Shell becomes the default on `testing`, then `stable` | Daily use for a week on real hardware without falling back to KDE screens |

---

## 5. Limits (honest)

- **Apps keep their own layouts.** Steam, Chrome, VS Code and KDE apps are styled (colours,
  buttons, corners, selections) but their insides are their own. Ravana Settings and, later,
  a Ravana Files app are the way to get Apple-level consistency there.
- **Real blur needs the compositor.** Ravana Shell's glass uses the wallpaper behind it; glass
  over *windows* (not just the wallpaper) needs a blur protocol in Quickshell or a small KWin
  integration, planned in phase 1.
- **Cloud screenshots can't show motion, blur or gestures**; those are confirmed on hardware.
