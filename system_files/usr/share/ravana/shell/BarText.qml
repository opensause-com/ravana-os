// Copyright (c) 2026 Ravana OS. All rights reserved.
// A menu-bar title (app name or a menu like "File"), with the macOS pill highlight when open.
import QtQuick
import QtQuick.Layouts
import org.ravana.ui as R

MouseArea {
    id: t
    property alias text: label.text
    property bool bold: false
    property bool active: false
    signal hovered()
    Layout.fillHeight: true
    implicitWidth: label.implicitWidth + 18
    hoverEnabled: true
    onContainsMouseChanged: if (containsMouse) t.hovered()
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 3; anchors.bottomMargin: 3
        radius: 6
        color: R.Theme.barText
        opacity: t.active ? 0.18 : (t.containsMouse ? 0.10 : 0)
        Behavior on opacity { NumberAnimation { duration: R.Theme.fast } }
    }
    Text {
        id: label
        anchors.centerIn: parent
        color: R.Theme.barText
        font.family: R.Theme.fontFamily
        font.pixelSize: 13
        font.weight: t.bold ? Font.Bold : Font.Normal
    }
}
