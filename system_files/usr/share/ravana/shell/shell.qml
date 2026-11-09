// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana Shell: the Ravana desktop (wallpaper, menu bar, dock, Launchpad) drawn entirely
// by Ravana on the Ravana UI kit. KWin stays underneath as the window engine.
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: shell

    Variants {
        model: Quickshell.screens
        Scope {
            id: perScreen
            required property var modelData
            Wallpaper { screen: perScreen.modelData }
            MenuBar { screen: perScreen.modelData }
            Dock { screen: perScreen.modelData; onLaunchpadRequested: launchpad.toggle() }
        }
    }

    // Ravana Shell is the notification server
    Notifications { id: notifications; screen: Quickshell.screens[0] }
    NotificationCenter { id: notificationCenter; screen: Quickshell.screens[0]; history: notifications.history }
    IpcHandler {
        target: "notifications"
        function toggle(): void { notificationCenter.toggle(); }
    }

    // Restart / Shut Down / Log Out alert
    PowerDialog { id: powerDialog; screen: Quickshell.screens[0] }
    IpcHandler {
        target: "power"
        function show(kind: string): void { powerDialog.show(kind); }
        function close(): void { powerDialog.close(); }
    }

    // Volume / brightness / keyboard-light HUD (fed by ravana-osd)
    Hud { screen: Quickshell.screens[0] }

    // One Launchpad, on the first screen
    Launchpad { id: launchpad; screen: Quickshell.screens[0] }
    Spotlight { id: spotlight; screen: Quickshell.screens[0] }
    IpcHandler {
        target: "spotlight"
        function toggle(): void { spotlight.toggle(); }
        function search(text: string): void { spotlight.open(text); }
    }

    // `qs ipc -p /usr/share/ravana/shell call launchpad toggle` (used by the F4 shortcut)
    IpcHandler {
        target: "launchpad"
        function toggle(): void { launchpad.toggle(); }
    }

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
