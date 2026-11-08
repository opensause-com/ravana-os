// Ravana menu bar (macOS-style):  Ravana menu | app menus ........ status icons | search | clock
var bar = new Panel;
bar.location = "top";
bar.height = Math.round(gridUnit * 1.6);
bar.floating = false;
try { bar.opacity = "translucent"; } catch (e) {}   // glass over the wallpaper

bar.addWidget("org.ravana.menu");
bar.addWidget("org.kde.plasma.appmenu");
bar.addWidget("org.kde.plasma.panelspacer");

var tray = bar.addWidget("org.kde.plasma.systemtray");

bar.addWidget("org.ravana.search");

var clock = bar.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", "true");
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd d MMM");
clock.writeConfig("dateDisplayFormat", "BesideTime");
