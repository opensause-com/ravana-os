// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana notifications: Ravana Shell is the system notification server
// (org.freedesktop.Notifications). Banners slide in top-right as glass cards; every
// notification is kept for Notification Center.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import org.ravana.ui as R

Scope {
    id: root
    property var screen
    property alias history: server.trackedNotifications

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
