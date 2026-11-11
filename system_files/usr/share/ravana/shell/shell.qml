// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana Shell: the Ravana desktop (wallpaper, menu bar, dock, Launchpad) drawn entirely
// by Ravana on the Ravana UI kit. KWin stays underneath as the window engine.
//
// Memory: surfaces you open now and then (Launchpad, Spotlight, Notification Center, the
// restart alert) are created when opened and freed after they close, on the screen of
// the window you're working in.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import org.kde.taskmanager as TaskManager

ShellRoot {
    id: shell

    // ---- which screen: the one holding the active window (else the first) ----
    TaskManager.TasksModel { id: focusTasks; groupMode: TaskManager.TasksModel.GroupDisabled }
    function activeScreen() {
        const i = focusTasks.activeTask;
        const g = (i && i.valid) ? focusTasks.data(i, TaskManager.AbstractTasksModel.ScreenGeometry) : null;
        if (g) {
            const cx = g.x + g.width / 2, cy = g.y + g.height / 2;
            for (const s of Quickshell.screens)
                if (cx >= s.x && cx < s.x + s.width && cy >= s.y && cy < s.y + s.height) return s;
        }
        return Quickshell.screens[0];
    }
    property var targetScreen: Quickshell.screens[0]

    // ---- shared system status (one set of checks for every menu bar) ----
    SystemStatus { id: sys }

    Variants {
        model: Quickshell.screens
        Scope {
            id: perScreen
            required property var modelData
            Wallpaper { screen: perScreen.modelData }
            MenuBar { screen: perScreen.modelData; focusOn: notifications.focusOn; sys: sys }
            Dock { screen: perScreen.modelData; onLaunchpadRequested: shell.launchpad("toggle") }
        }
    }

    // Ravana Shell is the notification server (always on)
    Notifications { id: notifications; screen: Quickshell.screens[0] }

    // ---- on-demand surfaces ----
    LazyLoader {
        id: ncLoader
        NotificationCenter {
            screen: shell.targetScreen
            history: notifications.history
            onVisibleChanged: if (!visible) ncLoader.active = false
        }
    }
    LazyLoader {
        id: padLoader
        Launchpad {
            screen: shell.targetScreen
            onVisibleChanged: if (!visible) padLoader.active = false
        }
    }
    LazyLoader {
        id: spotLoader
        Spotlight {
            screen: shell.targetScreen
            onVisibleChanged: if (!visible) spotLoader.active = false
        }
    }
    LazyLoader {
        id: powerLoader
        PowerDialog {
            screen: shell.targetScreen
            onVisibleChanged: if (!visible) powerLoader.active = false
        }
    }
    function bring(loader) {
        if (!loader.active) { shell.targetScreen = shell.activeScreen(); loader.active = true; }
        return loader.item;
    }
    function launchpad(action) {
        const p = bring(padLoader);
        if (action === "utilities") p.openUtilities(); else p.toggle();
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void { shell.bring(ncLoader).toggle(); }
    }
    IpcHandler {
        target: "spotlight"
        function toggle(): void { shell.bring(spotLoader).toggle(); }
        function search(text: string): void { shell.bring(spotLoader).open(text); }
    }
    // `qs ipc -p /usr/share/ravana/shell call launchpad toggle` (used by the F4 shortcut)
    IpcHandler {
        target: "launchpad"
        function toggle(): void { shell.launchpad("toggle"); }
        function utilities(): void { shell.launchpad("utilities"); }
    }
    IpcHandler {
        target: "power"
        function ask(kind: string): void { shell.bring(powerLoader).present(kind); }
        function close(): void { if (powerLoader.active) powerLoader.item.dismiss(); }
    }

    // Power connected: a short rising chime (laptops)
    Process { id: plugSound; command: ["pw-play", "--volume=0.6", "/usr/share/sounds/ravana/stereo/power-plug.wav"] }
    Connections {
        target: UPower.displayDevice
        function onStateChanged() {
            const d = UPower.displayDevice;
            if (d && d.isLaptopBattery && d.state === UPowerDeviceState.Charging && !plugSound.running)
                plugSound.running = true;
        }
    }

    // Update ready (staged by Software Update or the weekly automatic update): tell once
    Process {
        id: notifyUpdate
        // notify-send waits for a button and prints which one was chosen
        stdout: StdioCollector {
            onStreamFinished: {
                const a = text.trim();
                if (a === "restart") shell.bring(powerLoader).present("restart");
                else if (a === "default") Quickshell.execDetached(["ravana-settings", "update"]);
            }
        }
    }
    Connections {
        target: sys
        function onUpdateReadyChanged() {
            if (!sys.updateReady) return;
            notifyUpdate.command = ["notify-send", "-a", "Software Update", "-i", "ravana-logo",
                "-A", "restart=Restart Now", "-A", "default=Details",
                "Ravana OS update ready", "Restart to finish installing the new version."];
            notifyUpdate.running = true;
        }
    }
    // Administrator password sheet (Polkit agent, always registered)
    PolkitDialog { id: polkit; screen: Quickshell.screens[0] }
    IpcHandler {
        target: "polkit"
        function preview(): void { polkit.preview = true; }
        function close(): void { polkit.preview = false; }
    }

    // Volume / brightness / keyboard-light HUD (fed by ravana-osd)
    Hud { screen: Quickshell.screens[0] }

    // App menus: KDE's menu registrar lives in kded; make sure it's loaded (Plasma's shell did this)
    Process {
        running: true
        command: ["dbus-send", "--session", "--type=method_call", "--dest=org.kde.kded6",
                  "/kded", "org.kde.kded6.loadModule", "string:appmenu"]
    }

    // Tell the login splash the desktop is ready (Plasma's shell used to do this)
    Process {
        running: true
        command: ["dbus-send", "--session", "--type=method_call", "--dest=org.kde.KSplash",
                  "/KSplash", "org.kde.KSplash.setStage", "string:desktop"]
    }
}
