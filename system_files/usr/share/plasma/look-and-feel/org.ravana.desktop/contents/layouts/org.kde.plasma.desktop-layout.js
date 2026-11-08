// Ravana OS default desktop, modelled on macOS. Runs once for new users and from
// "Reset Ravana Look". The bars themselves are layout templates, so the updater and
// Plasma's "Add Panel" menu create exactly the same ones:
//   /usr/share/plasma/layout-templates/org.ravana.menubar
//   /usr/share/plasma/layout-templates/org.ravana.dock

var ds = desktops();
for (var i = 0; i < ds.length; i++) {
    ds[i].wallpaperPlugin = "org.kde.image";
    ds[i].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    ds[i].writeConfig("Image", "file:///usr/share/wallpapers/Ravana/");
}

loadTemplate("org.ravana.menubar");
loadTemplate("org.ravana.dock");
