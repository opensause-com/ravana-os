// Copyright (c) 2026 Ravana OS. All rights reserved.
// One menu-bar extra from an app's tray icon (Steam, Discord, …): click opens the app,
// right-click (or click when the app only has a menu) shows the app's own menu.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import org.ravana.ui as R

MouseArea {
    id: t
    required property var modelData
    property var barWindow
    Layout.preferredWidth: 26
    Layout.fillHeight: true
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: m => {
        if (m.button === Qt.MiddleButton) { modelData.secondaryActivate(); return; }
        if (m.button === Qt.RightButton || modelData.onlyMenu) {
            if (modelData.hasMenu) {
                const p = t.mapToItem(null, 0, t.height);
                modelData.display(t.barWindow, p.x, p.y);
            }
            return;
        }
        modelData.activate();
    }
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 3; anchors.bottomMargin: 3
        radius: 6
        color: R.Theme.text
        opacity: t.containsMouse ? 0.13 : 0
        Behavior on opacity { NumberAnimation { duration: R.Theme.fast } }
    }
    Image {
        anchors.centerIn: parent
        width: 16; height: 16
        sourceSize: Qt.size(32, 32)
        source: t.modelData.icon
        smooth: true
    }
}
