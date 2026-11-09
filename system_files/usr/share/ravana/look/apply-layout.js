// Ravana look update for an existing desktop: rebuild the menu bar and dock from the
// current Ravana templates, keeping the user's pinned dock apps and own wallpaper.
var pinned = [];
var ps = panels();
for (var i = 0; i < ps.length; i++) {
    var p = ps[i];
    if (p.location != "top" && p.location != "bottom") continue;
    var ws = p.widgets();
    for (var j = 0; j < ws.length; j++) {
        var w = ws[j];
        if (w.type == "org.kde.plasma.icontasks" || w.type == "org.kde.plasma.taskmanager" || w.type == "org.ravana.dockapps") {
            w.currentConfigGroup = ["General"];
            var l = w.readConfig("launchers", "");
            if (typeof l == "string") l = l.length ? l.split(",") : [];
            for (var k = 0; k < l.length; k++) {
                if (l[k] && pinned.indexOf(l[k]) < 0 && l[k].indexOf("liveinst") < 0) pinned.push(l[k]);
            }
        }
    }
    p.remove();
}

loadTemplate("org.ravana.menubar");
loadTemplate("org.ravana.dock");

if (pinned.length) {
    ps = panels();
    for (var i = 0; i < ps.length; i++) {
        var ws = ps[i].widgets("org.ravana.dockapps");
        for (var j = 0; j < ws.length; j++) {
            ws[j].currentConfigGroup = ["General"];
            ws[j].writeConfig("launchers", pinned.join(","));
            ws[j].reloadConfig();
        }
    }
}

// Wallpapers that came with the old base image are gone: switch those to Ravana.
// A wallpaper the user picked from their own files stays.
var ds = desktops();
for (var i = 0; i < ds.length; i++) {
    ds[i].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    var img = String(ds[i].readConfig("Image", ""));
    if (img == "" || (img.indexOf("/usr/share/") >= 0 && img.indexOf("/wallpapers/Ravana") < 0)) {
        ds[i].wallpaperPlugin = "org.kde.image";
        ds[i].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
        ds[i].writeConfig("Image", "file:///usr/share/wallpapers/Ravana/");
    }
}
print("Ravana look applied; kept " + pinned.length + " dock apps");
