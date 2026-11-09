// Ravana dock (macOS-style): Launchpad | apps | divider | Trash. Floating glass, centered, sized to its icons.
var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(gridUnit * 3.9);
dock.alignment = "center";
dock.lengthMode = "fit";
dock.floating = true;
dock.hiding = "none";
try { dock.opacity = "translucent"; } catch (e) {}

var launchpad = dock.addWidget("org.ravana.launchpad");   // macOS-style app grid
launchpad.currentConfigGroup = ["General"];
launchpad.writeConfig("icon", "ravana-launchpad");
launchpad.writeConfig("alphaSort", "true");
launchpad.writeConfig("showRecentApps", "false");
launchpad.writeConfig("showRecentDocs", "false");
launchpad.globalShortcut = "Alt+F1";

var tasks = dock.addWidget("org.ravana.dockapps");      // pinned + open apps, dots, names on hover
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "applications:org.kde.dolphin.desktop",
    "preferred://browser",
    "applications:steam.desktop",
    "applications:code.desktop",
    "applications:org.gnome.Ptyxis.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:systemsettings.desktop"
].join(","));

dock.addWidget("org.kde.plasma.trash");
