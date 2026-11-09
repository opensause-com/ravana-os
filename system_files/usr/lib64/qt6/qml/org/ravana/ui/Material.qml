// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana UI kit: glass material.
//   kind: "clear" (menu bar), "regular" (dock, Spotlight, Control Center, menus),
//         "thick" (sheets, alerts, sidebars)
// Glass is drawn from the wallpaper behind the surface (blur + vibrancy), then a tint,
// a fine light rim and a sheen along the top edge; optional floating shadow.
import QtQuick
import QtQuick.Effects

Item {
    id: m
    property string kind: "regular"
    property real radius: Theme.radiusCard
    property bool shadow: true
    property bool rim: kind !== "clear"
    property point origin: Qt.point(0, 0)        // top-left of this item on the screen
    property size screenSize: Qt.size(1920, 1080)

    RectangularShadow {
        visible: m.shadow && m.kind !== "clear"
        anchors.fill: parent
        radius: m.radius
        blur: 30
        spread: -2
        offset: Qt.vector2d(0, 10)
        color: Theme.shadow
    }

    Item {
        id: backdropSource
        anchors.fill: parent
        visible: false
        clip: true
        Image {
            x: -m.origin.x; y: -m.origin.y
            width: m.screenSize.width; height: m.screenSize.height
            source: Theme.wallpaper
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(m.screenSize.width / 2, m.screenSize.height / 2)
            asynchronous: true
        }
    }
    Rectangle { id: shape; anchors.fill: parent; radius: m.radius; visible: false; layer.enabled: true }
    MultiEffect {
        anchors.fill: parent
        source: backdropSource
        visible: m.kind !== "clear"
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        saturation: Theme.vibrancy
        maskEnabled: true
        maskSource: shape
    }

    Rectangle {
        anchors.fill: parent
        radius: m.radius
        color: Theme.glassTint(m.kind)
        border.width: m.rim ? 1 : 0
        border.color: Theme.glassRim
    }
    Rectangle {          // top sheen
        visible: m.rim
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, m.radius - 1)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.glassSheen }
            GradientStop { position: 0.3; color: "transparent" }
        }
    }
}
