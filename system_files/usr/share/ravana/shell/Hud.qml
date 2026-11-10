// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana HUD: a small glass capsule under the menu bar on the right for volume,
// brightness and keyboard light (a level bar) or a short message (layout, Wi-Fi…).
// Fed by /usr/libexec/ravana-osd over IPC.
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import org.kde.kirigami as Kirigami
import org.ravana.ui as R

PanelWindow {
    id: hud
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ravana-hud"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; right: true }
    margins { top: 38; right: 12 }
    implicitWidth: 300
    implicitHeight: 64
    color: "transparent"
    visible: shown > 0
    mask: Region {}                    // never takes clicks

    property string kind: "volume"     // volume | brightness | keyboard | microphone | text
    property int level: 0
    property string icon: ""
    property string message: ""

    property real shown: 0
    Behavior on shown { NumberAnimation { duration: hud.shown > 0.5 ? R.Theme.normal : R.Theme.bloom; easing.type: Easing.OutCubic } }
    Timer { id: away; interval: 1600; onTriggered: hud.shown = 0 }
    function present() { shown = 1; away.restart(); }

    function iconFor() {
        if (kind === "text") return icon;
        if (kind === "brightness") return "brightness-high-symbolic";
        if (kind === "keyboard") return "input-keyboard-brightness";
        if (kind === "microphone") return level === 0 ? "microphone-sensitivity-muted-symbolic" : "audio-input-microphone-symbolic";
        return level === 0 ? "audio-volume-muted-symbolic" : level < 34 ? "audio-volume-low-symbolic"
             : level < 67 ? "audio-volume-medium-symbolic" : "audio-volume-high-symbolic";
    }
    function titleFor() {
        return kind === "brightness" ? qsTr("Display") : kind === "keyboard" ? qsTr("Keyboard")
             : kind === "microphone" ? qsTr("Microphone") : qsTr("Sound");
    }

    Process { id: tap; command: ["pw-play", "--volume=0.5", "/usr/share/sounds/ravana/stereo/audio-volume-change.wav"] }

    IpcHandler {
        target: "hud"
        function level(kind: string, percent: int): void {
            hud.kind = kind; hud.level = percent; hud.present();
            if (kind === "volume" && !tap.running) tap.running = true;     // macOS-style volume feedback
        }
        function text(icon: string, message: string): void { hud.kind = "text"; hud.icon = icon; hud.message = message; hud.present(); }
    }

    Item {
        id: capsule
        anchors.fill: parent
        anchors.margins: 6
        opacity: hud.shown
        scale: 0.9 + 0.1 * hud.shown
        transformOrigin: Item.Top
        transform: Translate { y: (1 - hud.shown) * -8 }

        RectangularShadow {
            anchors.fill: bg; radius: bg.radius
            blur: 24; offset: Qt.vector2d(0, 6); color: R.Theme.shadow
        }
        Rectangle {
            id: bg
            anchors.fill: parent
            radius: height / 2
            color: R.Theme.glassTint("thick")
            border.width: 1; border.color: R.Theme.glassRim
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16; anchors.rightMargin: 20
            spacing: 12
            Kirigami.Icon {
                implicitWidth: 22; implicitHeight: 22
                source: hud.iconFor(); isMask: true; color: R.Theme.text
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Text {
                    text: hud.kind === "text" ? hud.message : hud.titleFor()
                    color: R.Theme.text
                    font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody; font.weight: Font.DemiBold
                    Layout.fillWidth: true; elide: Text.ElideRight
                }
                Rectangle {     // level bar
                    visible: hud.kind !== "text"
                    Layout.fillWidth: true
                    implicitHeight: 6; radius: 3
                    color: R.Theme.sliderTrack
                    Rectangle {
                        height: parent.height; radius: 3
                        width: parent.width * Math.max(0, Math.min(100, hud.level)) / 100
                        color: R.Theme.accent
                        Behavior on width { SpringAnimation { spring: 5; damping: 0.4; epsilon: 0.5 } }
                    }
                }
            }
            Text {
                visible: hud.kind !== "text"
                text: hud.level
                color: R.Theme.secondaryText
                font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeCaption
                font.features: { "tnum": 1 }
                Layout.preferredWidth: 22
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
