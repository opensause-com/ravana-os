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
    readonly property color sliderTrack: dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.13)
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
    // Springs (SpringAnimation): responsive, gently damped, no wobble
    readonly property real springStiffness: 4.2
    readonly property real springDamping: 0.42
    readonly property real springEpsilon: 0.25
    // Ravana motion signature: surfaces "bloom" out of what opened them —
    // a quick scale from 92% with a soft overshoot, opacity leading slightly.
    readonly property int bloom: 260
    readonly property real bloomFrom: 0.92
    readonly property real bloomOvershoot: 1.15
    readonly property int exit: 120

    // ---- UI kit v2: Ravana Glass ------------------------------------------------
    // Wallpaper behind the glass (Ravana Shell draws glass from it)
    readonly property string wallpaper: dark
        ? "file:///usr/share/wallpapers/RavanaLanka/contents/images/3840x2160.png"
        : "file:///usr/share/wallpapers/Ravana/contents/images_light/3840x2160.png"

    // Materials: clear (menu bar), regular (dock, popups), thick (sheets, sidebars)
    function glassTint(kind) {
        const a = kind === "clear" ? 0.0 : kind === "thick" ? (dark ? 0.70 : 0.78) : (dark ? 0.30 : 0.55);
        return dark ? Qt.rgba(0.15, 0.14, 0.16, a) : Qt.rgba(0.98, 0.98, 0.99, a);
    }
    readonly property color glassRim: dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.70)
    readonly property color glassSheen: dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.30)
    readonly property color shadow: Qt.rgba(0, 0, 0, dark ? 0.45 : 0.20)
    readonly property real vibrancy: 0.6          // saturation boost of what's behind glass

    // Shapes: fixed radii (Apple's "fixed"), capsule = height / 2, concentric = outer - padding
    readonly property int radiusWindow: 18
    readonly property int radiusCard: 16
    readonly property int radiusMenu: 12
    readonly property int radiusHighlight: 7
    readonly property int radiusTooltip: 8
    function concentric(outerRadius, padding) { return Math.max(4, outerRadius - padding); }

    // Type scale (Inter)
    readonly property int sizeCaption: 11
    readonly property int sizeBody: 13
    readonly property int sizeLarge: 22
    readonly property int sizeDisplay: 26
    readonly property int sizeClock: 96

    // Menu bar text sits on clear glass: always readable with a soft shadow
    readonly property color barText: dark ? "#ffffff" : "#1d1d1f"
}
