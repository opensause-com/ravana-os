// Ravana OS default desktop, modelled on macOS:
//   menu bar (top):  Ravana menu | app menu ..... status icons | search | clock
//   dock (bottom):   Launchpad | apps | Trash
// Runs once for new users (and from "Reset desktop look").

// ---- Wallpaper ----
var ds = desktops();
for (var i = 0; i < ds.length; i++) {
    ds[i].wallpaperPlugin = "org.kde.image";
    ds[i].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    ds[i].writeConfig("Image", "file:///usr/share/wallpapers/Ravana/");
}

// ---- Menu bar ----
var bar = new Panel;
bar.location = "top";
bar.height = Math.round(gridUnit * 1.6);
bar.floating = false;
// Glass over the wallpaper, solid when a window is maximized
try { bar.opacity = "adaptive"; } catch (e) {}

bar.addWidget("org.ravana.menu");                 // Apple-menu equivalent
bar.addWidget("org.kde.plasma.appmenu");          // the focused app's menus
bar.addWidget("org.kde.plasma.panelspacer");

var tray = bar.addWidget("org.kde.plasma.systemtray");

bar.addWidget("org.ravana.search");               // Spotlight (KRunner)

var clock = bar.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", "true");
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd d MMM");
clock.writeConfig("dateDisplayFormat", "BesideTime");

// ---- Dock: floating, centered, sized to its icons ----
var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(gridUnit * 3.4);
dock.alignment = "center";
dock.lengthMode = "fit";
dock.floating = true;
dock.hiding = "none";
try { dock.opacity = "translucent"; } catch (e) {}

// Launchpad: full-screen app grid (also on the Meta key)
var launchpad = dock.addWidget("org.kde.plasma.kickerdash");
launchpad.currentConfigGroup = ["General"];
launchpad.writeConfig("icon", "ravana-launchpad");
launchpad.writeConfig("showRecentApps", "false");
launchpad.writeConfig("showRecentDocs", "false");
launchpad.globalShortcut = "Alt+F1";

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "applications:org.kde.dolphin.desktop",
    "applications:org.mozilla.firefox.desktop",
    "applications:steam.desktop",
    "applications:code.desktop",
    "applications:org.gnome.Ptyxis.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:systemsettings.desktop"
].join(","));
tasks.writeConfig("indicateAudioStreams", "true");
tasks.writeConfig("iconSpacing", "1");
tasks.writeConfig("maxStripes", "1");
tasks.writeConfig("groupedTaskVisualization", "1");   // click a stack: show its windows

dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.kde.plasma.trash");
