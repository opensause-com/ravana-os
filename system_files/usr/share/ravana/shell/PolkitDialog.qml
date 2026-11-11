// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana's administrator password sheet (the system's Polkit agent): a centred glass card
// over a dimmed screen, like macOS's "… wants to make changes". Passwords go straight to
// the system's authentication (PAM) through Quickshell's Polkit agent and are never stored.
// Safety net: if Ravana can't register as the agent, KDE's agent is started instead.
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Polkit
import org.ravana.ui as R

Scope {
    id: root
    property var screen
    property bool preview: false            // screenshot test: show the sheet with sample text

    PolkitAgent { id: agent }
    readonly property var flow: agent.flow

    // fallback: no Ravana agent after 5 s -> KDE's agent so admin prompts always work
    Process { id: kdeAgent; command: ["sh", "-c", "exec /usr/libexec/kf6/polkit-kde-authentication-agent-1 2>/dev/null || exec /usr/libexec/polkit-kde-authentication-agent-1"] }
    Timer { interval: 5000; running: true; onTriggered: if (!agent.isRegistered) kdeAgent.running = true }

    PanelWindow {
        id: sheet
        screen: root.screen
        visible: root.preview || (agent.isActive && root.flow !== null && !root.flow.isCompleted)
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "ravana-polkit"
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        property real reveal: 0
        onVisibleChanged: if (visible) { reveal = 0; bloom.restart(); pw.text = ""; pw.forceActiveFocus(); }
        NumberAnimation { id: bloom; target: sheet; property: "reveal"; from: 0; to: 1
            duration: R.Theme.bloom; easing.type: Easing.OutBack; easing.overshoot: R.Theme.bloomOvershoot }

        function submit() {
            if (root.preview || !root.flow || !pw.text) return;
            root.flow.submit(pw.text);
            pw.text = "";
        }
        function cancel() {
            if (root.preview) { root.preview = false; return; }
            if (root.flow) root.flow.cancelAuthenticationRequest();
        }
        Connections {
            target: root.flow
            function onAuthenticationFailed() { shake.restart(); pw.text = ""; pw.forceActiveFocus(); }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.35 * Math.min(1, sheet.reveal * 1.5))
        }

        Item {
            id: card
            width: 340
            height: col.implicitHeight + 44
            anchors.centerIn: parent
            scale: R.Theme.bloomFrom + (1 - R.Theme.bloomFrom) * sheet.reveal
            opacity: Math.min(1, sheet.reveal * 1.6)
            property real dx: 0
            transform: Translate { x: card.dx }
            SequentialAnimation {
                id: shake
                loops: 2
                NumberAnimation { target: card; property: "dx"; to: -10; duration: 50 }
                NumberAnimation { target: card; property: "dx"; to: 10; duration: 80 }
                NumberAnimation { target: card; property: "dx"; to: 0; duration: 50 }
            }

            RectangularShadow {
                anchors.fill: glass; radius: glass.radius
                blur: 48; offset: Qt.vector2d(0, 18); color: R.Theme.shadow
            }
            Rectangle {
                id: glass
                anchors.fill: parent
                radius: R.Theme.radiusWindow
                color: R.Theme.glassTint("thick")
                border.width: 1; border.color: R.Theme.glassRim
            }

            ColumnLayout {
                id: col
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: 22
                spacing: 10

                Image {
                    Layout.alignment: Qt.AlignHCenter
                    source: R.Theme.dark ? "file:///usr/share/icons/hicolor/128x128/apps/ravana-logo-white.png"
                                         : "file:///usr/share/icons/hicolor/128x128/apps/ravana-logo.png"
                    sourceSize: Qt.size(56, 56)
                }
                Text {
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Ravana OS wants to make changes.")
                    color: R.Theme.text
                    font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody; font.weight: Font.Bold
                }
                Text {
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: root.preview ? qsTr("Authentication is required to install software.")
                                       : (root.flow ? root.flow.message : "")
                    color: R.Theme.secondaryText
                    font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeCaption
                }
                Text {
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Enter your password to allow this.")
                    color: R.Theme.secondaryText
                    font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeCaption
                }

                Rectangle {     // password capsule
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    implicitHeight: 30; radius: 15
                    color: R.Theme.dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)
                    border.width: 1; border.color: pw.activeFocus ? R.Theme.accent : R.Theme.blockBorder
                    TextInput {
                        id: pw
                        anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: (root.flow && root.flow.responseVisible) ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "●"
                        color: R.Theme.text
                        font.family: R.Theme.fontFamily; font.pixelSize: 13
                        focus: true
                        Keys.onReturnPressed: sheet.submit()
                        Keys.onEnterPressed: sheet.submit()
                        Keys.onEscapePressed: sheet.cancel()
                    }
                    Text {
                        textFormat: Text.PlainText
                        anchors.verticalCenter: parent.verticalCenter; x: 14
                        visible: !pw.text
                        text: qsTr("Password")
                        color: R.Theme.tertiaryText
                        font.family: R.Theme.fontFamily; font.pixelSize: 13
                    }
                }
                Text { textFormat: Text.PlainText;      // wrong password / extra messages from the system
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    visible: text.length > 0
                    text: root.flow && root.flow.supplementaryMessage ? root.flow.supplementaryMessage
                          : (root.flow && root.flow.failed ? qsTr("Incorrect password. Try again.") : "")
                    color: root.flow && root.flow.supplementaryIsError || (root.flow && root.flow.failed) ? R.Theme.accent : R.Theme.secondaryText
                    font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeCaption
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    spacing: 8
                    R.PushButton { Layout.fillWidth: true; text: qsTr("Cancel"); onClicked: sheet.cancel() }
                    R.PushButton { Layout.fillWidth: true; text: qsTr("OK"); primary: true; onClicked: sheet.submit() }
                }
            }
        }
    }
}
