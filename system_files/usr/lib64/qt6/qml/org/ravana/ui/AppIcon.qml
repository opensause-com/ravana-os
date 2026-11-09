// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana UI kit: app icon at a uniform size with a soft contact shadow, so the Dock,
// Apps view and Spotlight read as one consistent grid.
import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami

Item {
    id: a
    property var source
    property real size: 52
    implicitWidth: size
    implicitHeight: size

    Kirigami.Icon {
        id: icon
        anchors.fill: parent
        source: a.source
        visible: false
    }
    MultiEffect {
        anchors.fill: icon
        source: icon
        shadowEnabled: true
        shadowBlur: 0.45
        shadowVerticalOffset: Math.max(1, a.size * 0.03)
        shadowOpacity: Theme.dark ? 0.45 : 0.25
        shadowColor: "black"
    }
}
