// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana app switcher (⌘Tab): a centred glass bar of large app icons. The chosen app
// sits in a soft red-ringed tile with its name underneath. Opens with the Ravana bloom.
import QtQuick
import QtQuick.Effects
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.kwin as KWin
import org.ravana.ui as R

KWin.TabBoxSwitcher {
    id: tabBox
    currentIndex: list.currentIndex

    readonly property int iconSize: 96
    readonly property int tile: iconSize + 28

    Window {
        id: win
        visible: tabBox.visible
        flags: Qt.BypassWindowManagerHint | Qt.FramelessWindowHint
        color: "transparent"
        width: Math.min(tabBox.screenGeometry.width - 80, list.count * tabBox.tile + 2 * 18) + 60
        height: tabBox.tile + 64 + 60
        x: tabBox.screenGeometry.x + (tabBox.screenGeometry.width - width) / 2
        y: tabBox.screenGeometry.y + (tabBox.screenGeometry.height - height) / 2

        property real reveal: 0
        onVisibleChanged: if (visible) bloom.restart(); else reveal = 0
        NumberAnimation { id: bloom; target: win; property: "reveal"; from: 0; to: 1
            duration: R.Theme.bloom; easing.type: Easing.OutBack; easing.overshoot: R.Theme.bloomOvershoot }

        Item {
            id: stage
            anchors.fill: parent
            anchors.margins: 30
            scale: R.Theme.bloomFrom + (1 - R.Theme.bloomFrom) * win.reveal
            opacity: Math.min(1, win.reveal * 1.6)

            RectangularShadow {
                anchors.fill: glass; radius: glass.radius
                blur: 36; offset: Qt.vector2d(0, 12); color: R.Theme.shadow
            }
            Rectangle {
                id: glass
                anchors.fill: parent
                radius: 28
                color: R.Theme.glassTint("thick")
                border.width: 1
                border.color: R.Theme.glassRim
            }

            ListView {
                id: list
                anchors.top: parent.top; anchors.topMargin: 18
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(parent.width - 36, count * tabBox.tile)
                height: tabBox.tile
                orientation: ListView.Horizontal
                model: tabBox.model
                clip: true
                highlightMoveDuration: R.Theme.fast
                highlightFollowsCurrentItem: true
                highlight: Rectangle {
                    radius: 22
                    color: R.Theme.dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.07)
                    border.width: 2
                    border.color: R.Theme.accent
                }
                delegate: Item {
                    id: cell
                    required property int index
                    required property var model
                    width: tabBox.tile; height: tabBox.tile
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: tabBox.iconSize; height: width
                        source: cell.model.icon
                        opacity: cell.model.minimized ? 0.55 : 1
                        scale: ListView.isCurrentItem ? 1.04 : 1
                        Behavior on scale { NumberAnimation { duration: R.Theme.fast; easing.type: Easing.OutBack } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: tabBox.model.activate(cell.index)
                    }
                }
            }
            Text {
                anchors.top: list.bottom; anchors.topMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 40
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideMiddle
                text: list.currentItem ? (list.currentItem.model.caption || "") : ""
                color: R.Theme.text
                font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody; font.weight: Font.DemiBold
            }
        }
    }
}
