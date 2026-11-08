// Ravana dock (macOS-style): Launchpad | apps | Trash. Floating glass, centered, sized to its icons.
var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(gridUnit * 3.4);
dock.alignment = "center";
dock.lengthMode = "fit";
dock.floating = true;
dock.hiding = "none";
try { dock.opacity = "translucent"; } catch (e) {}

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
tasks.writeConfig("groupedTaskVisualization", "1");

dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.kde.plasma.trash");
