// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana switch: red when on, white knob with a soft spring.
import QtQuick
import org.ravana.ui as R

Rectangle {
    id: sw
    property bool on: false
    signal toggled()
    implicitWidth: 40; implicitHeight: 24; radius: 12
    color: on ? R.Theme.accent : R.Theme.sliderTrack
    Behavior on color { ColorAnimation { duration: R.Theme.fast } }
    Rectangle {
        width: 20; height: 20; radius: 10; y: 2
        x: sw.on ? sw.width - width - 2 : 2
        color: "white"
        Behavior on x { SpringAnimation { spring: 5; damping: 0.38; epsilon: 0.3 } }
    }
    MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: sw.toggled() }
}
