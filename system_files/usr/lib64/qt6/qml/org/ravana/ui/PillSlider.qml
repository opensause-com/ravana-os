// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana UI kit: wide pill slider with the icon inside the track (Control Center style).
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: slider
    property string iconName
    property real value: 0.5            // 0..1
    property bool available: true
    signal moved(real value)            // while dragging
    signal released(real value)         // when let go

    // What the slider shows: the pointer's position while dragging (and for a moment after,
    // until the system reports the new level), otherwise the bound value. The bound value
    // itself is never written here, so it keeps following the system.
    property real live: 0
    readonly property real shown: drag.pressed || hold.running ? live : value
    Timer { id: hold; interval: 1500 }

    implicitHeight: 28
    opacity: available ? 1 : 0.45

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.sliderTrack
        clip: true

        Rectangle {
            id: fill
            height: parent.height
            width: Math.max(parent.height, parent.width * slider.shown)
            radius: height / 2
            color: Theme.sliderFill
            border.width: Theme.dark ? 0 : 1
            border.color: Qt.rgba(0, 0, 0, 0.08)
            Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: Theme.fast } }
        }

        Kirigami.Icon {
            anchors.verticalCenter: parent.verticalCenter
            x: 7
            width: 15; height: 15
            source: slider.iconName
            isMask: true
            color: Theme.sliderIcon
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        enabled: slider.available
        preventStealing: true
        function at(mx) { return Math.max(0, Math.min(1, mx / width)); }
        onPressed: mouse => { slider.live = at(mouse.x); slider.moved(slider.live); }
        onPositionChanged: mouse => { if (pressed) { slider.live = at(mouse.x); slider.moved(slider.live); } }
        onReleased: { hold.restart(); slider.released(slider.live); }
        onCanceled: hold.stop()
        onWheel: wheel => {
            slider.live = Math.max(0, Math.min(1, slider.shown + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
            hold.restart();
            slider.released(slider.live);
        }
    }
}
