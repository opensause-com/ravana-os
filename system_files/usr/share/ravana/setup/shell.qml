// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana Setup Assistant: runs once on a new account's first login. Full-screen over
// the wallpaper, one step per page: Welcome → Appearance → Wi-Fi → Gestures and keys
// → Ready. Steps glide sideways; nothing here can lose data and every step can be skipped.
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import org.kde.kirigami as Kirigami
import org.ravana.ui as R
import "../settings"

ShellRoot {
    id: app
    property int step: 0
    readonly property int steps: 5
    property var st: ({})
    property var nets: []

    function kv(text) {
        const s = {};
        text.split("\n").forEach(l => { const i = l.indexOf("="); if (i > 0) s[l.slice(0, i)] = l.slice(i + 1); });
        return s;
    }
    Process { id: status; running: true; command: ["/usr/libexec/ravana-cc", "status"]
        stdout: StdioCollector { onStreamFinished: app.st = app.kv(text) } }
    Process { id: lister; command: ["/usr/libexec/ravana-cc", "wifi-list"]
        stdout: StdioCollector { onStreamFinished: app.nets = text.split("\n").filter(l => l.length).map(l => l.split("\t")) } }
    Process { id: runner }
    function run(args) { runner.command = args; runner.running = true; refresh.restart(); }
    Timer { id: refresh; interval: 1200; onTriggered: { status.running = true; if (app.step === 2) lister.running = true; } }
    onStepChanged: if (step === 2) lister.running = true

    Process { id: done; command: ["sh", "-c", "mkdir -p \"$HOME/.config\" && touch \"$HOME/.config/ravana-setup-done\""] }
    function finish() { done.running = true; quitTimer.start(); win.shown = 0; }
    Timer { id: quitTimer; interval: 400; onTriggered: Qt.quit() }

    IpcHandler { target: "setup"; function go(n: int): void { app.step = n; } }

    PanelWindow {
        id: win
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "ravana-setup"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        property real shown: 1

        // blurred wallpaper behind everything
        Image {
            id: wp
            anchors.fill: parent
            source: R.Theme.wallpaper
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(win.width / 2, win.height / 2)
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: wp
            blurEnabled: true; blur: 1.0; blurMax: 64
            saturation: 0.3
            opacity: win.shown
            Behavior on opacity { NumberAnimation { duration: 380 } }
        }
        Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, R.Theme.dark ? 0.35 : 0.1); opacity: win.shown }

        // the card
        Item {
            id: card
            width: 640; height: 520
            anchors.centerIn: parent
            opacity: win.shown
            scale: 0.96 + 0.04 * win.shown
            Behavior on opacity { NumberAnimation { duration: 380 } }

            RectangularShadow { anchors.fill: glass; radius: glass.radius; blur: 60; offset: Qt.vector2d(0, 24); color: R.Theme.shadow }
            Rectangle {
                id: glass
                anchors.fill: parent
                radius: 24
                color: R.Theme.glassTint("thick")
                border.width: 1; border.color: R.Theme.glassRim
            }

            // steps slide sideways
            Item {
                anchors.fill: parent
                anchors.margins: 40
                anchors.bottomMargin: 90
                clip: true
                Row {
                    id: strip
                    x: -app.step * (card.width - 80)
                    Behavior on x { NumberAnimation { duration: 460; easing.type: Easing.OutQuint } }

                    // 0 — Welcome
                    Page {
                        Image { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 30
                            source: R.Theme.dark ? "file:///usr/share/icons/hicolor/256x256/apps/ravana-logo-white.png"
                                                 : "file:///usr/share/icons/hicolor/256x256/apps/ravana-logo.png"
                            sourceSize: Qt.size(120, 120) }
                        Heading { text: qsTr("Welcome to Ravana") ; size: 34 }
                        Body { text: qsTr("Let's get your Mac-like home ready. It only takes a moment.") }
                    }
                    // 1 — Appearance
                    Page {
                        Heading { text: qsTr("Choose a look") }
                        Body { text: qsTr("Light or Dark. You can change it any time in Control Center.") }
                        Row {
                            Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 18
                            spacing: 32
                            Repeater {
                                model: [ { id: "light", name: qsTr("Light") }, { id: "dark", name: qsTr("Dark") } ]
                                Column {
                                    id: look
                                    required property var modelData
                                    readonly property bool active: (modelData.id === "dark") === R.Theme.dark
                                    spacing: 10
                                    Rectangle {
                                        width: 200; height: 125; radius: 14
                                        border.width: look.active ? 3 : 1
                                        border.color: look.active ? R.Theme.accent : R.Theme.blockBorder
                                        Image {
                                            anchors.fill: parent; anchors.margins: look.active ? 3 : 1
                                            fillMode: Image.PreserveAspectCrop
                                            sourceSize: Qt.size(400, 250)
                                            source: look.modelData.id === "dark"
                                                ? "file:///usr/share/wallpapers/RavanaLanka/contents/screenshot.png"
                                                : "file:///usr/share/wallpapers/Ravana/contents/screenshot_light.png"
                                        }
                                        MouseArea { anchors.fill: parent; onClicked: app.run(["/usr/libexec/ravana-appearance", look.modelData.id]) }
                                    }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: look.modelData.name
                                        color: R.Theme.text; font.family: R.Theme.fontFamily; font.pixelSize: 14
                                        font.weight: look.active ? Font.DemiBold : Font.Normal }
                                }
                            }
                        }
                    }
                    // 2 — Wi-Fi
                    Page {
                        Heading { text: qsTr("Get online") }
                        Body { text: app.st.net_wired === "1" ? qsTr("You're connected by cable. You can skip this step.")
                                    : qsTr("Pick a Wi-Fi network. Secured networks ask for their password.") }
                        SettingsGroup {
                            Layout.topMargin: 12
                            SettingsRow { visible: app.nets.length === 0; label: lister.running ? qsTr("Looking for networks…") : qsTr("No Wi-Fi networks found"); last: true }
                            Repeater {
                                model: app.nets.slice(0, 5)
                                SettingsRow {
                                    required property var modelData
                                    required property int index
                                    label: modelData[1]
                                    detail: modelData[0] === "*" ? qsTr("Connected") : ((modelData[3] || "--") !== "--" ? "🔒" : "")
                                    chevron: modelData[0] !== "*"
                                    last: index === Math.min(4, app.nets.length - 1)
                                    onClicked: app.run(["/usr/libexec/ravana-cc", "wifi-connect", modelData[1]])
                                }
                            }
                        }
                    }
                    // 3 — Gestures and keys
                    Page {
                        Heading { text: qsTr("Move like a pro") }
                        SettingsGroup {
                            Layout.topMargin: 12
                            SettingsRow { label: qsTr("Search anything"); detail: "⌘ Space" }
                            SettingsRow { label: qsTr("All your apps"); detail: qsTr("F4 · four fingers up") }
                            SettingsRow { label: qsTr("Switch apps"); detail: "⌘ Tab" }
                            SettingsRow { label: qsTr("See every window"); detail: qsTr("three fingers up") }
                            SettingsRow { label: qsTr("Switch desktops"); detail: qsTr("three fingers sideways") }
                            SettingsRow { label: qsTr("Screenshot"); detail: "⇧ ⌘ 4"; last: true }
                        }
                    }
                    // 4 — Ready
                    Page {
                        Image { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 30
                            source: "file:///usr/share/icons/hicolor/256x256/apps/ravana-logo.png"
                            sourceSize: Qt.size(110, 110) }
                        Heading { text: qsTr("You're all set") ; size: 34 }
                        Body { text: qsTr("Ravana keeps itself up to date and your files safe. Enjoy.") }
                    }
                }
            }

            // dots + buttons
            Row {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 38
                anchors.left: parent.left; anchors.leftMargin: 40
                spacing: 8
                Repeater {
                    model: app.steps
                    Rectangle {
                        required property int index
                        width: index === app.step ? 18 : 7; height: 7; radius: 3.5
                        color: index === app.step ? R.Theme.accent : R.Theme.tertiaryText
                        Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                    }
                }
            }
            Row {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 28
                anchors.right: parent.right; anchors.rightMargin: 40
                spacing: 10
                PushButton { visible: app.step > 0 && app.step < app.steps - 1; text: qsTr("Back"); onClicked: app.step-- }
                PushButton { visible: app.step > 0 && app.step < app.steps - 1; text: qsTr("Skip"); onClicked: app.step++ }
                PushButton {
                    primary: true
                    text: app.step === 0 ? qsTr("Get Started") : app.step === app.steps - 1 ? qsTr("Start Using Ravana") : qsTr("Continue")
                    onClicked: app.step === app.steps - 1 ? app.finish() : app.step++
                }
            }
            focus: true
            Keys.onReturnPressed: app.step === app.steps - 1 ? app.finish() : app.step++
        }
    }

    component Page: ColumnLayout {
        width: 560
        height: 390
        spacing: 10
    }
    component Heading: Text {
        property int size: 26
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 12
        color: R.Theme.text
        font.family: R.Theme.fontFamily; font.pixelSize: size; font.weight: Font.Bold
    }
    component Body: Text {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        color: R.Theme.secondaryText
        font.family: R.Theme.fontFamily; font.pixelSize: 14
    }
}
