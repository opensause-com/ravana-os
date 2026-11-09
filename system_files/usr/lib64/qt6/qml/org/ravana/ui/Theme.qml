// Copyright (c) 2026 Ravana OS. All rights reserved.
/*
 * Ravana UI kit: design tokens shared by every Ravana surface
 * (menu bar widgets, Control Center, Spotlight, dialogs, Settings).
 * Light and dark follow the system colour scheme.
 */
pragma Singleton
import QtQuick

QtObject {
    id: theme

    property SystemPalette palette: SystemPalette { colorGroup: SystemPalette.Active }
    readonly property bool dark: palette.window.hslLightness < 0.5

    // Brand
    readonly property color accent: "#d21f3c"
    readonly property color accentHover: "#e8435a"
    readonly property color textOnAccent: "#ffffff"

    // Text
    readonly property color text: dark ? "#f5f5f7" : "#1d1d1f"
    readonly property color secondaryText: dark ? Qt.rgba(1, 1, 1, 0.58) : Qt.rgba(0, 0, 0, 0.52)
    readonly property color tertiaryText: dark ? Qt.rgba(1, 1, 1, 0.38) : Qt.rgba(0, 0, 0, 0.34)

    // Surfaces (on top of the blurred glass a popup already has)
    readonly property color block: dark ? Qt.rgba(1, 1, 1, 0.075) : Qt.rgba(1, 1, 1, 0.62)
    readonly property color blockBorder: dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)
    readonly property color bubble: dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.08)
    readonly property color hover: dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)
    readonly property color sliderTrack: dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)
    readonly property color sliderFill: dark ? "#f5f5f7" : "#ffffff"
    readonly property color sliderIcon: dark ? "#3a3a3c" : "#6e6e73"

    // Shape and rhythm
    readonly property int radiusLarge: 18
    readonly property int radiusMedium: 13
    readonly property int radiusSmall: 8
    readonly property int gap: 10
    readonly property int pad: 12

    // Type
    readonly property string fontFamily: "Inter"
    readonly property int titleSize: 13
    readonly property int bodySize: 12
    readonly property int captionSize: 11

    // Motion (Ravana: quick and confident)
    readonly property int fast: 140
    readonly property int normal: 220
}
