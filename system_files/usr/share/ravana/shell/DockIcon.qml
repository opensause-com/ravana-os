// Copyright (c) 2026 Ravana OS. All rights reserved.
// One dock item: magnifies with the pointer, dot when open, pulse while launching.
import QtQuick
import org.kde.kirigami as Kirigami
import org.ravana.ui as R

Item {
    id: it
    property var dock
    property var iconSource
    property string label
    property bool running: false
    property bool launching: false
    signal clicked()
    signal middleClicked()

    readonly property real s: dock.scaleFor(mapToItem(dock.contentItem, width / 2, 0).x)
    width: dock.cell * (1 + (s - 1) * 0.85)
    height: dock.iconSize
    Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

    property real pulse: 0
    SequentialAnimation on pulse {
        running: it.launching
        loops: Animation.Infinite
        alwaysRunToEnd: true
        NumberAnimation { to: 1; duration: 420; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: 420; easing.type: Easing.InOutSine }
    }

    R.AppIcon {
        id: icon
        size: dock.iconSize * it.s * (1 + it.pulse * 0.06)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        source: it.iconSource
        Behavior on size { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
    }

    Rectangle {   // open-app dot
        width: 5; height: 5; radius: 2.5
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 4
        color: it.launching ? R.Theme.accent : R.Theme.text
        opacity: it.running || it.launching ? 0.85 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    Rectangle {   // name bubble
        visible: mouse.containsMouse && it.label.length > 0
        anchors.horizontalCenter: icon.horizontalCenter
        anchors.bottom: icon.top
        anchors.bottomMargin: 10
        width: name.implicitWidth + 20; height: 26
        radius: 8
        color: R.Theme.dark ? Qt.rgba(0.12, 0.12, 0.14, 0.92) : Qt.rgba(0.98, 0.98, 0.99, 0.95)
        border.width: 1
        border.color: R.Theme.dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)
        Text {
            id: name
            anchors.centerIn: parent
            text: it.label
            color: R.Theme.text
            font.family: R.Theme.fontFamily
            font.pixelSize: 12
            renderType: Text.NativeRendering
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: m => m.button === Qt.MiddleButton ? it.middleClicked() : it.clicked()
    }
}
