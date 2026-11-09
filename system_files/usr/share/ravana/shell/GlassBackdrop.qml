// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana glass: a blurred slice of the wallpaper under this surface, a tint, a fine rim.
// (Quickshell has no compositor blur, so the glass is drawn from the wallpaper itself.)
import QtQuick
import QtQuick.Effects
import org.ravana.ui as R

Item {
    id: glass
    property Item window                 // the window content item (for screen position)
    property real radius: R.Theme.radiusLarge
    property real tint: 0.42
    property point origin: Qt.point(0, 0) // this item's top-left in screen coordinates
    property size screenSize: Qt.size(1920, 1080)

    Item {
        id: clip
        anchors.fill: parent
        visible: false
        clip: true
        Image {
            x: -glass.origin.x; y: -glass.origin.y
            width: glass.screenSize.width; height: glass.screenSize.height
            source: Paths.wallpaper
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(glass.screenSize.width / 2, glass.screenSize.height / 2)
        }
    }
    MultiEffect {
        anchors.fill: parent
        source: clip
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        saturation: 0.6          // vibrancy: colours behind the glass glow through
        maskEnabled: true
        maskSource: mask
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: glass.radius
        visible: false
        layer.enabled: true
    }
    // tint, then a fine light rim (brighter along the top edge, like real glass)
    Rectangle {
        anchors.fill: parent
        radius: glass.radius
        color: R.Theme.dark ? Qt.rgba(0.16, 0.15, 0.17, glass.tint) : Qt.rgba(0.98, 0.98, 0.99, glass.tint)
        border.width: 1
        border.color: R.Theme.dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.65)
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: glass.radius - 1
        color: "transparent"
        border.width: 1
        border.color: "transparent"
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, R.Theme.dark ? 0.07 : 0.25) }
            GradientStop { position: 0.35; color: "transparent" }
        }
    }
}
