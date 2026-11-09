// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana popup surface: rounded, frosted panel with a fine rim and shadow.
// Opens with the Ravana "bloom": it grows out of whatever opened it.
import QtQuick
import QtQuick.Effects
import Quickshell
import org.ravana.ui as R

Item {
    id: s
    default property alias content: inner.data
    property real radius: R.Theme.radiusCard
    property int growFrom: Item.Top          // Item.Top (menu bar), Item.Bottom (dock), …

    readonly property bool open: QsWindow.window ? QsWindow.window.visible : true
    property real reveal: 0
    onOpenChanged: open ? bloomIn.restart() : (bloomIn.stop(), reveal = 0)
    Component.onCompleted: if (open) bloomIn.restart()
    NumberAnimation {
        id: bloomIn
        target: s; property: "reveal"; from: 0; to: 1
        duration: R.Theme.bloom
        easing.type: Easing.OutBack; easing.overshoot: R.Theme.bloomOvershoot
    }

    Item {
        id: stage
        anchors.fill: parent
        transformOrigin: s.growFrom
        scale: R.Theme.bloomFrom + (1 - R.Theme.bloomFrom) * s.reveal
        opacity: Math.min(1, s.reveal * 1.6)

        RectangularShadow {
            anchors.fill: bg
            radius: bg.radius
            blur: 28
            spread: 0
            offset: Qt.vector2d(0, 8)
            color: R.Theme.shadow
        }
        Rectangle {
            id: bg
            anchors.fill: parent
            anchors.margins: 14
            radius: s.radius
            color: R.Theme.glassTint("thick")
            border.width: 1
            border.color: R.Theme.glassRim
            Item { id: inner; anchors.fill: parent }
        }
    }
}
