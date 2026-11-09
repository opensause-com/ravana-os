// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana power alert (Restart / Shut Down / Log Out): a centred glass alert that blooms
// in over a dimmed screen, with a 60-second countdown like macOS. ⏎ confirms, Esc cancels.
// The action itself goes to KDE's session manager, which closes apps safely.
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import org.ravana.ui as R

PanelWindow {
    id: dlg
    visible: false
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ravana-power"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    property string kind: "restart"            // restart | shutdown | logout
    property int secondsLeft: 60
    readonly property var info: ({
        restart:  { title: qsTr("Are you sure you want to restart your computer now?"), verb: qsTr("Restart"),
                    later: qsTr("restart"), call: "logoutAndReboot" },
        shutdown: { title: qsTr("Are you sure you want to shut down your computer now?"), verb: qsTr("Shut Down"),
                    later: qsTr("shut down"), call: "logoutAndShutdown" },
        logout:   { title: qsTr("Are you sure you want to quit all apps and log out now?"), verb: qsTr("Log Out"),
                    later: qsTr("log you out"), call: "logout" }
    })[kind]

    function present(k) { kind = k; secondsLeft = 60; visible = true; reveal = 0; bloom.restart(); }
    function dismiss() { visible = false; }
    function confirm() {
        visible = false;
        act.command = ["dbus-send", "--session", "--type=method_call", "--dest=org.kde.Shutdown",
                       "/Shutdown", "org.kde.Shutdown." + info.call];
        act.running = true;
    }
    Process { id: act }
    Timer { interval: 1000; repeat: true; running: dlg.visible; onTriggered: if (--dlg.secondsLeft <= 0) dlg.confirm() }

    property real reveal: 0
    NumberAnimation { id: bloom; target: dlg; property: "reveal"; from: 0; to: 1
        duration: R.Theme.bloom; easing.type: Easing.OutBack; easing.overshoot: R.Theme.bloomOvershoot }

    Rectangle {      // dim the desktop
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35 * Math.min(1, dlg.reveal * 1.5))
        MouseArea { anchors.fill: parent; onClicked: dlg.dismiss() }
    }

    Item {
        id: alert
        width: 300
        height: col.implicitHeight + 40
        anchors.centerIn: parent
        scale: R.Theme.bloomFrom + (1 - R.Theme.bloomFrom) * dlg.reveal
        opacity: Math.min(1, dlg.reveal * 1.6)
        focus: true
        Keys.onEscapePressed: dlg.dismiss()
        Keys.onReturnPressed: dlg.confirm()
        Keys.onEnterPressed: dlg.confirm()

        RectangularShadow {
            anchors.fill: card; radius: card.radius
            blur: 48; offset: Qt.vector2d(0, 18); color: R.Theme.shadow
        }
        Rectangle {
            id: card
            anchors.fill: parent
            radius: R.Theme.radiusWindow
            color: R.Theme.glassTint("thick")
            border.width: 1; border.color: R.Theme.glassRim
            MouseArea { anchors.fill: parent }
        }
        ColumnLayout {
            id: col
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            anchors.margins: 20
            spacing: 12
            Image {
                Layout.alignment: Qt.AlignHCenter
                source: R.Theme.dark ? "file:///usr/share/icons/hicolor/128x128/apps/ravana-logo-white.png"
                                     : "file:///usr/share/icons/hicolor/128x128/apps/ravana-logo.png"
                sourceSize: Qt.size(56, 56)
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: dlg.info.title
                color: R.Theme.text
                font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody; font.weight: Font.Bold
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: qsTr("If you do nothing, the computer will %1 automatically in %2 seconds.").arg(dlg.info.later).arg(dlg.secondsLeft)
                color: R.Theme.secondaryText
                font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeCaption
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 8
                Repeater {
                    model: [ { label: qsTr("Cancel"), primary: false }, { label: dlg.info.verb, primary: true } ]
                    Rectangle {
                        id: btn
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: 9
                        color: modelData.primary ? R.Theme.accent : (R.Theme.dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.07))
                        opacity: area.pressed ? 0.75 : 1
                        Text {
                            anchors.centerIn: parent
                            text: btn.modelData.label
                            color: btn.modelData.primary ? R.Theme.textOnAccent : R.Theme.text
                            font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody
                            font.weight: btn.modelData.primary ? Font.DemiBold : Font.Normal
                        }
                        MouseArea { id: area; anchors.fill: parent; onClicked: btn.modelData.primary ? dlg.confirm() : dlg.dismiss() }
                    }
                }
            }
        }
    }
}
