// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana push button: a small capsule; "primary" is red.
import QtQuick

Rectangle {
    id: b
    property string text
    property bool primary: false
    signal clicked()
    implicitWidth: label.implicitWidth + 24; implicitHeight: 26
    radius: 7
    color: primary ? Theme.accent : (Theme.dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.06))
    opacity: area.pressed ? 0.75 : 1
    border.width: primary ? 0 : 1
    border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.08)
    Text {
        textFormat: Text.PlainText
        id: label
        anchors.centerIn: parent
        text: b.text
        color: b.primary ? Theme.textOnAccent : Theme.text
        font.family: Theme.fontFamily; font.pixelSize: Theme.sizeBody
    }
    MouseArea { id: area; anchors.fill: parent; onClicked: b.clicked() }
}
