#!/usr/bin/env bash
# Runs inside the Ravana image: starts a headless Plasma session for a fresh user
# and screenshots the desktop, Launchpad, Spotlight, the Ravana menu and a window.
set -uo pipefail
OUT=/shots
{ ls -la /usr/bin/kwin_wayland* /usr/libexec/kwin* 2>&1; file /usr/bin/kwin_wayland 2>&1; head -c 600 /usr/bin/kwin_wayland | strings | head -20; echo; ls /usr/share/icons; } > "$OUT/kwin-info.txt" 2>&1
useradd -m -s /bin/bash ravana 2>/dev/null || true
install -d -m 700 -o ravana -g ravana /tmp/xdg-ravana
chmod 666 /dev/dri/* 2>/dev/null || true
ls -la /dev/dri >> "$OUT/kwin-info.txt" 2>&1

cat > /home/ravana/session.sh <<'SESSION'
#!/usr/bin/env bash
OUT=/shots
log() { echo "[$(date +%T)] $*" >> "$OUT/steps.log"; }
shot() {
  sleep "${2:-3}"
  log "capturing $1"
  python3 /capture.py "$OUT/$1.png" >> "$OUT/steps.log" 2>&1 && log "shot $1" || log "FAILED shot $1"
}
send() { dbus-send --session --type=method_call --print-reply "$@" >/dev/null 2>&1; }

log "session started"
python3 -c "import dbus" >> "$OUT/steps.log" 2>&1 && log "dbus-python ok" || log "no dbus-python"
for d in /usr/libexec/kactivitymanagerd /usr/lib64/libexec/kactivitymanagerd; do [ -x "$d" ] && { "$d" >/dev/null 2>&1 & break; }; done
/usr/bin/kded6 >/dev/null 2>&1 &
sleep 2
if [ -f /usr/share/ravana/shell/shell.qml ] && command -v quickshell >/dev/null; then
  RAVANA_SHELL=1
  RAVANA_SHELL_TEST=1 quickshell -p /usr/share/ravana/shell >"$OUT/plasmashell.log" 2>&1 &
  log "started Ravana Shell"
else
  plasmashell --no-respawn >"$OUT/plasmashell.log" 2>&1 &
fi
sleep 45
shot 01-desktop 1
if [ -n "${RAVANA_SHELL:-}" ]; then
  QS="qs ipc -p /usr/share/ravana/shell call"
  $QS launchpad toggle >> "$OUT/steps.log" 2>&1; shot 20-shell-launchpad 2; $QS launchpad toggle >/dev/null 2>&1; sleep 1
  $QS menu toggle >> "$OUT/steps.log" 2>&1; shot 21-shell-menu 2; $QS menu toggle >/dev/null 2>&1; sleep 1
  $QS controlcenter toggle >> "$OUT/steps.log" 2>&1; shot 22-shell-control-center 2; $QS controlcenter toggle >/dev/null 2>&1; sleep 1
  $QS dock menu 0 >> "$OUT/steps.log" 2>&1; shot 28-shell-dock-menu 2; $QS dock close >/dev/null 2>&1; sleep 1
  notify-send -a "Ravana OS" -i ravana-os "Welcome to Ravana" "Notifications now come from Ravana Shell." >> "$OUT/steps.log" 2>&1
  shot 23-shell-notification 2
  # Light mode
  /usr/libexec/ravana-appearance light >> "$OUT/steps.log" 2>&1; sleep 4
  shot 24-shell-light 2
  $QS launchpad toggle >/dev/null 2>&1; shot 25-shell-light-launchpad 2; $QS launchpad toggle >/dev/null 2>&1; sleep 1
  $QS controlcenter toggle >/dev/null 2>&1; shot 26-shell-light-control-center 2; $QS controlcenter toggle >/dev/null 2>&1; sleep 1
  /usr/libexec/ravana-appearance dark >> "$OUT/steps.log" 2>&1; sleep 3
fi

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

# Control Center: give it a shortcut, then trigger exactly that widget
CC=$(dbus-send --session --print-reply --dest=org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript string:'
var p = panels(); for (var i = 0; i < p.length; i++) { var w = p[i].widgets("org.ravana.controlcenter"); if (w.length) { w[0].globalShortcut = "Meta+Ctrl+F11"; print(w[0].id); } }' 2>/dev/null | grep -o '"[0-9]*' | tr -d '"' | head -1)
log "control center widget id: ${CC:-none}"
[ -n "$CC" ] && sleep 1 && send --dest=org.kde.kglobalaccel /component/plasmashell org.kde.kglobalaccel.Component.invokeShortcut string:"activate widget $CC"
shot 10-control-center 3
[ -n "$CC" ] && send --dest=org.kde.kglobalaccel /component/plasmashell org.kde.kglobalaccel.Component.invokeShortcut string:"activate widget $CC"
sleep 1

dolphin /usr/share >/dev/null 2>&1 &
sleep 6
shot 05-window 2
if [ -n "${QS:-}" ]; then
  $QS appmenu first >> "$OUT/steps.log" 2>&1; shot 27-shell-app-menu 2; $QS appmenu close >/dev/null 2>&1; sleep 1
fi
systemsettings >/dev/null 2>&1 &
shot 06-settings 8
kinfocenter >/dev/null 2>&1 &
shot 07-about 8

command -v gnome-disks >/dev/null && { gnome-disks >/dev/null 2>&1 & }
shot 09-gtk-app 6

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

cat > /home/ravana/wrapper.sh <<'WRAP'
#!/usr/bin/env bash
OUT=/shots
/usr/libexec/ravana-gpu-check   # same check a real login runs before KWin starts
grep -A3 '^\[Plugins\]' "$HOME/.config/kwinrc" >> "$OUT/steps.log" 2>&1
kwin_wayland --virtual --no-lockscreen --width 1920 --height 1080 --socket wayland-ravana > "$OUT/kwin.log" 2>&1 &
KPID=$!
WPID=
export WAYLAND_DISPLAY=wayland-ravana
sleep 4
/home/ravana/session.sh &
SPID=$!
for i in $(seq 1 300); do
  if ! kill -0 $KPID 2>/dev/null; then
    wait $KPID; echo "[$(date +%T)] kwin exited with code $? after ${i}s" >> "$OUT/steps.log"; break
  fi
  if ! kill -0 $SPID 2>/dev/null; then echo "[$(date +%T)] session finished" >> "$OUT/steps.log"; break; fi
  [ $((i % 10)) -eq 0 ] && echo "[$(date +%T)] alive ${i}s" >> "$OUT/steps.log"
  sleep 1
done
kill $SPID $KPID $WPID 2>/dev/null
WRAP
chmod +x /home/ravana/wrapper.sh
chown ravana:ravana /home/ravana/wrapper.sh

timeout 360 runuser -u ravana -- env -i HOME=/home/ravana USER=ravana LOGNAME=ravana \
  PATH=/usr/local/bin:/usr/bin:/bin XDG_RUNTIME_DIR=/tmp/xdg-ravana \
  XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=KDE KDE_FULL_SESSION=true KDE_SESSION_VERSION=6 \
  QT_QPA_PLATFORM=wayland LANG=en_US.UTF-8 KWIN_SCREENSHOT_NO_PERMISSION_CHECKS=1 \
  QT_FORCE_STDERR_LOGGING=1 QT_LOGGING_RULES="kwin_*.info=true" \
  dbus-run-session -- /home/ravana/wrapper.sh > "$OUT/session-all.log" 2>&1
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
