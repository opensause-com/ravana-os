// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana notifications: Ravana Shell is the system notification server
// (org.freedesktop.Notifications). Banners slide in top-right as glass cards; every
// notification is kept for Notification Center.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications
import org.ravana.ui as R

Scope {
    id: root
    property var screen
    property alias history: server.trackedNotifications

    // Focus (Do Not Disturb) is stored where KDE keeps it: plasmanotifyrc [DoNotDisturb] Until
    property bool focusOn: false
    FileView {
        id: dndFile
        path: Quickshell.env("HOME") + "/.config/plasmanotifyrc"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.readFocus()
        onLoadFailed: root.focusOn = false
    }
    function readFocus() {
        const m = /\[DoNotDisturb\][^\[]*?Until=([^\n]+)/.exec(dndFile.text());
        root.focusOn = !!m && new Date(m[1].trim()) > new Date();
    }
    Timer { interval: 60000; repeat: true; running: true; onTriggered: root.readFocus() }   // timed Focus ends

    // banners currently on screen
    ListModel { id: banners }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: n => {
            n.tracked = true;
            // Focus (Do Not Disturb): keep it for Notification Center, show no banner,
            // except critical alerts (low battery, failures) which always come through
            if (root.focusOn && n.urgency !== 2) return;
            banners.insert(0, { note: n });
            if (banners.count > 4) banners.remove(banners.count - 1);
        }
    }

    PanelWindow {
        screen: root.screen
        visible: banners.count > 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "ravana-notifications"
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; right: true }
        margins { top: 34; right: 8 }
        implicitWidth: 380
        implicitHeight: Math.max(1, column.implicitHeight + 20)
        color: "transparent"

        ColumnLayout {
            id: column
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 6
            Repeater {
                model: banners
                NotificationCard {
                    required property var note
                    required property int index
                    Layout.fillWidth: true
                    notification: note
                    onDone: banners.remove(index)
                }
            }
        }
    }
}
