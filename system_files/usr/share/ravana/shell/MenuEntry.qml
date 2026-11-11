// Copyright (c) 2026 Ravana OS. All rights reserved.
import QtQuick
import QtQuick.Layouts
import org.ravana.ui as R

MouseArea {
    id: e
    property alias text: label.text
    signal activated()
    property bool keyFocus: false          // highlighted from the keyboard
    readonly property bool lit: containsMouse || keyFocus
    Layout.fillWidth: true
    implicitHeight: 28
    hoverEnabled: true
    onClicked: e.activated()
    Rectangle {
        anchors.fill: parent
        radius: 6
        color: R.Theme.accent
        opacity: e.lit ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 90 } }
    }
    Text {
        textFormat: Text.PlainText
        id: label
        anchors.verticalCenter: parent.verticalCenter
        x: 12
        color: e.lit ? R.Theme.textOnAccent : R.Theme.text
        font.family: R.Theme.fontFamily
        font.pixelSize: 13
        renderType: Text.NativeRendering
    }
}
