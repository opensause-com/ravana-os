// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana push button: a small capsule; "primary" is red.
import QtQuick
import org.ravana.ui as R

Rectangle {
    id: b
    property string text
    property bool primary: false
    signal clicked()
    implicitWidth: label.implicitWidth + 24; implicitHeight: 26
    radius: 7
    color: primary ? R.Theme.accent : (R.Theme.dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.06))
    opacity: area.pressed ? 0.75 : 1
    border.width: primary ? 0 : 1
    border.color: R.Theme.dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.08)
    Text {
        id: label
        anchors.centerIn: parent
        text: b.text
        color: b.primary ? R.Theme.textOnAccent : R.Theme.text
        font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody
    }
    MouseArea { id: area; anchors.fill: parent; onClicked: b.clicked() }
}
