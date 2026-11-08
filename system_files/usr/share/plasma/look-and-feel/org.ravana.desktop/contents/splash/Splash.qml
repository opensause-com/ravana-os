/*
 * Ravana OS login splash (shown between login and the desktop).
 * Crown fades in and settles, crimson glow breathes, a thin progress line fills
 * as Plasma starts. Pure QtQuick, no extra modules.
 */
import QtQuick 2.15

Rectangle {
    id: root
    color: "#0C0C0E"
    property int stage   // set by KSplash, 1..6

    Item {
        id: content
        anchors.centerIn: parent
        width: 320
        height: 330
        opacity: 0
        scale: 0.9

        Image {
            id: glow
            source: "images/glow.png"
            width: crown.width * 2
            height: width
            anchors.centerIn: crown
            smooth: true
            opacity: 0.35
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.9; duration: 1500; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.35; duration: 1500; easing.type: Easing.InOutSine }
            }
        }

        Image {
            id: crown
            source: "images/crown.png"
            width: 190
            height: 190
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            smooth: true
            mipmap: true
        }

        Image {
            id: word
            source: "images/wordmark.png"
            width: 150
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: crown.bottom
            anchors.topMargin: 14
            smooth: true
            mipmap: true
            opacity: 0
        }

        Rectangle {
            id: track
            width: 150
            height: 2
            radius: 1
            color: "#1FFFFFFF"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: word.bottom
            anchors.topMargin: 34
            Rectangle {
                height: parent.height
                radius: 1
                color: "#D21F3C"
                width: parent.width * Math.min(1, Math.max(0, root.stage) / 6)
                Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            }
        }
    }

    SequentialAnimation {
        running: true
        ParallelAnimation {
            NumberAnimation { target: content; property: "opacity"; to: 1; duration: 650; easing.type: Easing.OutCubic }
            NumberAnimation { target: content; property: "scale"; to: 1; duration: 900; easing.type: Easing.OutBack }
        }
        NumberAnimation { target: word; property: "opacity"; to: 0.9; duration: 500; easing.type: Easing.OutCubic }
    }
}
