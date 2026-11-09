// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana popup surface: rounded, dark/light frosted panel with a fine rim and shadow.
import QtQuick
import QtQuick.Effects
import org.ravana.ui as R

Item {
    id: s
    default property alias content: inner.data
    property real radius: R.Theme.radiusLarge

    RectangularShadow {
        anchors.fill: bg
        radius: bg.radius
        blur: 28
        spread: 0
        offset: Qt.vector2d(0, 8)
        color: Qt.rgba(0, 0, 0, R.Theme.dark ? 0.55 : 0.22)
    }
    Rectangle {
        id: bg
        anchors.fill: parent
        anchors.margins: 14
        radius: s.radius
        color: R.Theme.dark ? Qt.rgba(0.11, 0.105, 0.12, 0.94) : Qt.rgba(0.97, 0.97, 0.98, 0.96)
        border.width: 1
        border.color: R.Theme.dark ? Qt.rgba(1, 1, 1, 0.13) : Qt.rgba(0, 0, 0, 0.08)
        Item { id: inner; anchors.fill: parent }
    }
}
