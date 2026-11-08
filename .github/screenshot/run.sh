#!/usr/bin/env bash
# Runs inside the Ravana image: starts a headless Plasma session for a fresh user
# and screenshots the desktop, Launchpad, Spotlight, the Ravana menu and a window.
set -uo pipefail
OUT=/shots
useradd -m -s /bin/bash ravana 2>/dev/null || true
install -d -m 700 -o ravana -g ravana /tmp/xdg-ravana

cat > /home/ravana/session.sh <<'SESSION'
#!/usr/bin/env bash
OUT=/shots
log() { echo "[$(date +%T)] $*" >> "$OUT/steps.log"; }
shot() {
  sleep "${2:-3}"
  log "capturing $1"
  if python3 /capture.py "$OUT/$1.png" >> "$OUT/steps.log" 2>&1; then log "shot $1"
  elif spectacle -b -n -f -o "$OUT/$1.png" >> "$OUT/steps.log" 2>&1; then log "shot $1 (spectacle)"
  else log "FAILED shot $1"; fi
}
send() { dbus-send --session --type=method_call --print-reply "$@" >/dev/null 2>&1; }

log "session started"
python3 -c "import dbus" >> "$OUT/steps.log" 2>&1 && log "dbus-python ok" || log "no dbus-python"
plasmashell --no-respawn >"$OUT/plasmashell.log" 2>&1 &
sleep 30
shot 01-desktop 1

send --dest=org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.activateLauncherMenu
shot 02-launchpad
send --dest=org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.activateLauncherMenu
sleep 2

krunner >/dev/null 2>&1 &
sleep 4
send --dest=org.kde.krunner /App org.kde.krunner.App.query string:"sys"
shot 03-spotlight 4
send --dest=org.kde.krunner /App org.kde.krunner.App.toggleDisplay
sleep 2

# Ravana menu: give it a shortcut, then trigger it
send --dest=org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript string:'
var p = panels(); for (var i = 0; i < p.length; i++) { var w = p[i].widgets("org.ravana.menu"); if (w.length) { w[0].globalShortcut = "Meta+Ctrl+F12"; print("menu widget " + w[0].id); } }'
sleep 2
for a in $(seq 1 60); do
  send --dest=org.kde.kglobalaccel /component/plasmashell org.kde.kglobalaccel.Component.invokeShortcut string:"activate widget $a"
done
shot 04-ravana-menu
send --dest=org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript string:'print(JSON.stringify(panels().map(function(p){return {loc:p.location,len:p.lengthMode,h:p.height,widgets:p.widgets().map(function(w){return w.type})}})))' 
dbus-send --session --type=method_call --print-reply --dest=org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript string:'print(JSON.stringify(panels().map(function(p){return {loc:p.location,len:p.lengthMode,h:p.height,widgets:p.widgets().map(function(w){return w.type})}})))' > "$OUT/panels.txt" 2>&1

dolphin /usr/share >/dev/null 2>&1 &
sleep 6
shot 05-window 2
systemsettings >/dev/null 2>&1 &
shot 06-settings 8
kinfocenter >/dev/null 2>&1 &
shot 07-about 8

# Registered desktop shortcuts (are the Mac ones active?)
dbus-send --session --print-reply --dest=org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.allShortcutInfos > "$OUT/shortcuts-kwin.txt" 2>&1
dbus-send --session --print-reply --dest=org.kde.kglobalaccel /component/org_kde_spectacle_desktop org.kde.kglobalaccel.Component.allShortcutInfos > "$OUT/shortcuts-spectacle.txt" 2>&1

# Simulate an existing user taking the look update (rebuild bars, keep pins)
dbus-send --session --print-reply --dest=org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "string:$(cat /usr/share/ravana/look/apply-layout.js)" > "$OUT/look-update.txt" 2>&1
shot 08-after-look-update 6
log done
SESSION
chmod +x /home/ravana/session.sh
chown -R ravana:ravana /home/ravana
chmod 777 "$OUT"

timeout 300 runuser -u ravana -- env -i HOME=/home/ravana USER=ravana LOGNAME=ravana \
  PATH=/usr/local/bin:/usr/bin:/bin XDG_RUNTIME_DIR=/tmp/xdg-ravana \
  XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=KDE KDE_FULL_SESSION=true KDE_SESSION_VERSION=6 \
  QT_QPA_PLATFORM=wayland LANG=en_US.UTF-8 KWIN_SCREENSHOT_NO_PERMISSION_CHECKS=1 \
  KWIN_COMPOSE=Q QT_LOGGING_RULES="kwin_*.warning=true" \
  dbus-run-session -- kwin_wayland --virtual --no-lockscreen --width 1920 --height 1080 \
  --exit-with-session /home/ravana/session.sh > "$OUT/session-all.log" 2>&1
grep -v "dbus-daemon" "$OUT/session-all.log" > "$OUT/session.log" || true
rm -f "$OUT/session-all.log"
echo "session exit: $?"
cp /home/ravana/.config/plasma-org.kde.plasma.desktop-appletsrc "$OUT/" 2>/dev/null || true
# Shortcut merge for existing users
mkdir -p /tmp/sctest/.config
HOME=/tmp/sctest XDG_CONFIG_HOME=/tmp/sctest/.config /usr/libexec/ravana-apply-shortcuts
cp /tmp/sctest/.config/kglobalshortcutsrc "$OUT/shortcuts-merged.txt" 2>/dev/null || echo "merge produced nothing" > "$OUT/shortcuts-merged.txt"
# Window decoration + keyd sanity
grep -A6 kdecoration2 /etc/xdg/kwinrc > "$OUT/decoration.txt" 2>&1
keyd check /etc/keyd/default.conf > "$OUT/keyd-check.txt" 2>&1
ls -la "$OUT"
