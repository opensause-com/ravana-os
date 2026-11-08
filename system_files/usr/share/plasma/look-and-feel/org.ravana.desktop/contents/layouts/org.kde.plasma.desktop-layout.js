// Ravana OS default desktop: top bar + floating centered dock (macOS-style).
// Runs once for new users (and when "Use desktop layout from theme" is applied).

// ---- Wallpaper ----
var ds = desktops();
for (var i = 0; i < ds.length; i++) {
    ds[i].wallpaperPlugin = "org.kde.image";
    ds[i].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    ds[i].writeConfig("Image", "file:///usr/share/wallpapers/Ravana/");
}

// ---- Top bar: launcher, global app menu, ... , tray, clock ----
var bar = new Panel;
bar.location = "top";
bar.height = Math.round(gridUnit * 1.8);
bar.floating = false;

var launcher = bar.addWidget("org.kde.plasma.kickoff");
launcher.currentConfigGroup = ["General"];
launcher.writeConfig("icon", "ravana-logo");

bar.addWidget("org.kde.plasma.appmenu");
bar.addWidget("org.kde.plasma.panelspacer");
bar.addWidget("org.kde.plasma.systemtray");

var clock = bar.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", "true");
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd d MMM");
clock.writeConfig("dateDisplayFormat", "BesideTime");

// ---- Dock: floating, centered, sized to its icons, dodges windows ----
var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(gridUnit * 3.2);
dock.alignment = "center";
dock.lengthMode = "fit";
dock.floating = true;
dock.hiding = "dodgewindows";

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

dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.kde.plasma.trash");
