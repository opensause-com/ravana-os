#!/usr/bin/env bash
# Fast lane: lay the commit's system files over the image before anything starts
if [ -d /overlay ]; then
  # login screen test needs SDDM's greeter (the full build installs it)
  command -v sddm-greeter-qt6 >/dev/null || timeout 240 dnf5 install -y -q --setopt=install_weak_deps=False sddm > /shots/sddm-install.log 2>&1 || true
  cp -a --no-preserve=ownership /overlay/. / && echo "overlay applied" > /shots/overlay.txt
  chmod +x /usr/libexec/ravana-* 2>/dev/null || true
  # the image's plain-config build step, so new settings show up without a build
  [ -f /fastlane-config.sh ] && bash /fastlane-config.sh > /shots/fastlane-config.log 2>&1
fi
# Runs inside the Ravana image: starts a headless Plasma session for a fresh user
# and screenshots the desktop, Launchpad, Spotlight, the Ravana menu and a window.
set -uo pipefail
OUT=/shots
{ ls -la /usr/bin/kwin_wayland* /usr/libexec/kwin* 2>&1; file /usr/bin/kwin_wayland 2>&1; head -c 600 /usr/bin/kwin_wayland | strings | head -20; echo; ls /usr/share/icons; } > "$OUT/kwin-info.txt" 2>&1
useradd -m -s /bin/bash ravana 2>/dev/null || true
install -d -m 700 -o ravana -g ravana /tmp/xdg-ravana
chmod 666 /dev/dri/* 2>/dev/null || true
find /usr/share/icons/Colloid-Red-Dark /usr/share/icons/breeze-dark -name 'system-shutdown*' -o -name 'system-reboot*' -o -name 'system-suspend*' -o -name 'user-identity*' 2>/dev/null | head -40 > "$OUT/power-icons.txt"
ls -R /usr/lib64/qt6/qml/Quickshell/Services 2>/dev/null | grep -iE "polkit|qmldir|^/" > "$OUT/qs-services.txt" 2>&1
cp /usr/lib64/qt6/qml/Quickshell/Services/Polkit/quickshell-service-polkit.qmltypes "$OUT/" 2>/dev/null; rpm -q quickshell >> "$OUT/qs-services.txt" 2>&1
# reference for Ravana's lock/logout screens: the exact Plasma greeter/logout code in this image
{ find /usr/share /usr/lib64/qt6/qml -name 'LockScreen*.qml' -o -name 'Logout*.qml' -o -name 'MainBlock.qml' -o -name 'Greeter*.qml' 2>/dev/null;
  ls -R /usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents | head -80; rpm -ql kscreenlocker plasma-workspace 2>/dev/null | grep -iE 'lockscreen|logout|greet' | head -60; } > "$OUT/lock-files.txt" 2>&1
cp /usr/lib64/qt6/qml/org/kde/plasma/extras/PasswordField.qml "$OUT/PasswordField.qml" 2>/dev/null || find /usr/lib64/qt6/qml -name 'PasswordField.qml' -exec cp {} "$OUT/" \; 2>/dev/null
find /usr/share /usr/lib64/qt6/qml \( -path '*lockscreen*' -o -path '*logout*' -o -path '*kscreenlocker*' \) -name '*.qml' 2>/dev/null | tar czf "$OUT/lock-qml.tgz" -T - 2>/dev/null || true
{ ls -la /etc/systemd/system/display-manager.service; rpm -qa | grep -iE "sddm|plasma-login|plasmalogin|gdm|greetd|lightdm" ;
  ls /etc/plasmalogin* /etc/sddm* 2>&1; rpm -ql plasma-login-manager 2>/dev/null | grep -iE "qml|conf|theme|service" | head -60;
  rpm -ql sddm 2>/dev/null | grep -iE "themes" | head; } > "$OUT/login-themes.txt" 2>&1
{ rpm -ql plasma-login-manager; echo "== qml/package refs in the greeter =="; for b in $(rpm -ql plasma-login-manager | grep -E '/(bin|libexec)/'); do echo "-- $b"; strings "$b" | grep -iE 'qml|lookandfeel|look-and-feel|shells/|theme|wallpaper' | sort -u | head -40; done; cat /etc/plasmalogin.conf /usr/lib/plasmalogin/plasmalogin.conf.d/* 2>/dev/null; } > "$OUT/plm.txt" 2>&1
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
  [ -x /usr/libexec/ravana-osd ] && /usr/libexec/ravana-osd >"$OUT/ravana-osd.log" 2>&1 &
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
  $QS launchpad utilities >> "$OUT/steps.log" 2>&1; shot 45-launchpad-folder 2; $QS launchpad toggle >/dev/null 2>&1; sleep 1
  $QS menu toggle >> "$OUT/steps.log" 2>&1; shot 21-shell-menu 2; $QS menu toggle >/dev/null 2>&1; sleep 1
  $QS controlcenter toggle >> "$OUT/steps.log" 2>&1; shot 22-shell-control-center 2; $QS controlcenter toggle >/dev/null 2>&1; sleep 1
  $QS spotlight search "fi" >> "$OUT/steps.log" 2>&1; shot 29-shell-spotlight 3; $QS spotlight toggle >/dev/null 2>&1; sleep 1
  $QS spotlight search "12*7+1" >> "$OUT/steps.log" 2>&1; shot 30-shell-spotlight-calc 2; $QS spotlight toggle >/dev/null 2>&1; sleep 1
  $QS controlcenter page wifi >> "$OUT/steps.log" 2>&1; shot 31-shell-cc-wifi 3; $QS controlcenter toggle >/dev/null 2>&1; sleep 1
  $QS hud level volume 65 >> "$OUT/steps.log" 2>&1; shot 32-shell-hud 1
  notify-send -a Steam -i steam "Download complete" "Your game is ready to play." 2>/dev/null; sleep 6
  $QS notifications toggle >> "$OUT/steps.log" 2>&1; shot 33-shell-notification-center 2; $QS notifications toggle >/dev/null 2>&1; sleep 1
  /usr/libexec/kwin-tabbox-preview /usr/share/kwin/tabbox/ravana/contents/ui/main.qml >> "$OUT/tabbox.log" 2>&1 &
  TB=$!; shot 34-shell-app-switcher 4; kill $TB 2>/dev/null; sleep 1
  ravana-settings appearance >/dev/null 2>&1 &
  sleep 5; shot 35-settings-appearance 1
  { echo "settings window: $($QS appmenu info 2>&1)"; rpm -ql quickshell 2>/dev/null | grep -i '\.desktop'; } >> "$OUT/appid.txt"
  SQ="qs ipc -p /usr/share/ravana/settings call settings open"
  $SQ about >> "$OUT/steps.log" 2>&1; shot 36-settings-about 2
  $SQ trackpad >/dev/null 2>&1; shot 37-settings-trackpad 2
  pkill -f "qs -p /usr/share/ravana/settings" 2>/dev/null; pkill -f "quickshell -p /usr/share/ravana/settings" 2>/dev/null; sleep 1
  /usr/libexec/kscreenlocker_greet --testing >> "$OUT/lockscreen.log" 2>&1 &
  LK=$!; sleep 6; shot 38-lock-screen 1
  grep -q "Failed to load lockscreen QML" "$OUT/lockscreen.log" && echo "LOCK SCREEN FELL BACK TO KDE'S BUILT-IN LOCKER" >> "$OUT/steps.log"
  kill $LK 2>/dev/null; sleep 1
  G=$(ls /usr/libexec/ksmserver-logout-greeter /usr/lib64/libexec/ksmserver-logout-greeter 2>/dev/null | head -1)
  [ -n "$G" ] && { "$G" --windowed >> "$OUT/logout.log" 2>&1 & LG=$!; sleep 5; shot 40-logout-screen 1; kill $LG 2>/dev/null; sleep 1; }
  if command -v sddm-greeter-qt6 >/dev/null; then
    sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/ravana >> "$OUT/login.log" 2>&1 & LG2=$!
    sleep 6; shot 41-login-screen 1; kill $LG2 2>/dev/null; sleep 1
  fi
  /usr/libexec/ravana-setup --force >> "$OUT/setup.log" 2>&1 & ST=$!
  sleep 5; shot 42-setup-welcome 1
  SU="qs ipc -p /usr/share/ravana/setup call setup go"
  $SU 1 >> "$OUT/steps.log" 2>&1; sleep 1; shot 43-setup-look 1
  $SU 3 >/dev/null 2>&1; sleep 1; shot 44-setup-keys 1
  kill $ST 2>/dev/null; pkill -f "share/ravana/setup" 2>/dev/null; sleep 1
  /usr/libexec/ravana-cc focus on >/dev/null 2>&1; sleep 3
  notify-send -a Messages "Quiet please" "This banner should not appear while Focus is on" 2>/dev/null; sleep 2
  shot 46-focus-on 1; /usr/libexec/ravana-cc focus off >/dev/null 2>&1; sleep 1
  $QS controlcenter join "Ravana Home" >> "$OUT/steps.log" 2>&1; shot 47-wifi-password 2; $QS controlcenter toggle >/dev/null 2>&1; sleep 1
  $QS power ask restart >> "$OUT/steps.log" 2>&1; shot 39-power-dialog 2; $QS power close >/dev/null 2>&1; sleep 1
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
  { echo "== appmenu diag =="; echo "QT_QPA_PLATFORMTHEME=${QT_QPA_PLATFORMTHEME:-unset}";
    busctl --user list 2>/dev/null | grep -iE "appmenu|kded|dolphin" ;
    dbus-send --session --print-reply --dest=org.kde.kded6 /kded org.kde.kded6.loadedModules 2>&1 | tr -s ' \n' ' ' ; echo;
    for d in $(busctl --user list 2>/dev/null | awk '/dolphin/{print $1}'); do busctl --user tree "$d" 2>&1 | grep -i menu; done; } > "$OUT/appmenu.txt" 2>&1
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
