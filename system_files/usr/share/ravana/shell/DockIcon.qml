// Copyright (c) 2026 Ravana OS. All rights reserved.
// One dock item: magnifies with the pointer, dot when open, pulse while launching.
import QtQuick
import org.kde.kirigami as Kirigami
import org.ravana.ui as R

Item {
    id: it
    property var host                 // the Dock window (sizes, magnification)
    property var iconSource
    property string label
    property bool running: false
    property bool launching: false
    signal clicked()
    signal middleClicked()
    signal rightClicked()

    readonly property real s: host.scaleFor(mapToItem(host.contentItem, width / 2, 0).x)
    width: host.cell * (1 + (s - 1) * 0.85)
    height: host.iconSize
    Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

    // Ravana launch: the icon leaps and lands with a settle while the app starts
    property real lift: 0
    SequentialAnimation on lift {
        running: it.launching
        loops: Animation.Infinite
        alwaysRunToEnd: true
        NumberAnimation { to: 1; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation { to: 0; duration: 520; easing.type: Easing.OutBounce }
        PauseAnimation { duration: 120 }
    }
    // New items grow in; a click gives a quick press-and-spring
    property real appear: 0
    Component.onCompleted: appearAnim.start()
    NumberAnimation { id: appearAnim; target: it; property: "appear"; from: 0; to: 1
        duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
    property real press: mouse.pressed ? 0.88 : 1
    Behavior on press { SpringAnimation { spring: 6; damping: 0.32; epsilon: 0.005 } }

    R.AppIcon {
        id: icon
        size: host.iconSize * it.s
        scale: it.appear * it.press
        transformOrigin: Item.Bottom
        anchors.bottomMargin: it.lift * host.iconSize * 0.42
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
        visible: mouse.containsMouse && it.label.length > 0 && !(host.menuOpen || false)
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
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: m => m.button === Qt.MiddleButton ? it.middleClicked()
                      : m.button === Qt.RightButton ? it.rightClicked() : it.clicked()
        onPressAndHold: it.rightClicked()
    }
}
