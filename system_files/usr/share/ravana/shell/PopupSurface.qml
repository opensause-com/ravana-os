// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana popup surface: rounded, dark/light frosted panel with a fine rim and shadow.
import QtQuick
import QtQuick.Effects
import org.ravana.ui as R

Item {
    id: s
    default property alias content: inner.data
    property real radius: R.Theme.radiusCard

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
