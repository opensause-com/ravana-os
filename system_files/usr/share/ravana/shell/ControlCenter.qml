// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana Control Center (Ravana Shell): Wi-Fi, Bluetooth, Focus, Appearance,
// display brightness and sound. Backend: /usr/libexec/ravana-cc.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import org.kde.kirigami as Kirigami
import org.ravana.ui as R

PopupWindow {
    id: cc
    property var barWindow
    anchor.window: barWindow
    anchor.rect.x: barWindow ? barWindow.width - implicitWidth + 6 : 0
    anchor.rect.y: barWindow ? barWindow.height : 0
    grabFocus: Quickshell.env("RAVANA_SHELL_TEST") !== "1"   // no pointer in the cloud test
    visible: false
    color: "transparent"
    implicitWidth: 340 + 28
    implicitHeight: (page ? detail.implicitHeight : col.implicitHeight) + 2 * R.Theme.pad + 28
    onVisibleChanged: if (!visible) { page = ""; askSsid = ""; }

    // Expanded module ("" = the grid of modules)
    property string page: ""
    property var listRows: []
    Process {
        id: lister
        stdout: StdioCollector {
            onStreamFinished: cc.listRows = text.split("\n").filter(l => l.length).map(l => l.split("\t"))
        }
    }
    function openPage(p) {
        page = p; listRows = [];
        lister.command = ["/usr/libexec/ravana-cc", p === "wifi" ? "wifi-list" : p === "sound" ? "sinks" : "bt-list"];
        lister.running = true;
    }
    property real pageShift: 0
    onPageChanged: { pageShift = 1; pageAnim.restart(); }
    NumberAnimation { id: pageAnim; target: cc; property: "pageShift"; to: 0; duration: R.Theme.normal; easing.type: Easing.OutCubic }

    property var st: ({})
    function flag(k) { return st[k] === "1"; }

    Process {
        id: status
        command: ["/usr/libexec/ravana-cc", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = {};
                text.split("\n").forEach(l => { const i = l.indexOf("="); if (i > 0) s[l.slice(0, i)] = l.slice(i + 1); });
                cc.st = s;
            }
        }
    }
    Process { id: action }
    function showPage(p) { visible = true; openPage(p); }

    // joining a new secured Wi-Fi: the password goes to the helper on stdin only
    property string askSsid: ""
    property string joinError: ""
    Process {
        id: joiner
        stdinEnabled: true
        onStarted: { write(wifiPassword.text + "\n"); wifiPassword.text = ""; }
        onExited: code => {
            if (code === 0) { cc.askSsid = ""; cc.joinError = ""; }
            else cc.joinError = qsTr("Couldn't join. Check the password and try again.");
            cc.openPage("wifi"); refreshSoon.restart();
        }
    }
    function join() {
        if (!wifiPassword.text || joiner.running) return;
        joiner.command = ["/usr/libexec/ravana-cc", "wifi-connect", cc.askSsid, "--password-stdin"];
        joiner.running = true;
    }
    Process { id: appearance; command: ["/usr/libexec/ravana-appearance", "toggle"] }
    function act(args) { action.command = ["/usr/libexec/ravana-cc"].concat(args); action.running = true; refreshSoon.restart(); }
    Timer { id: refreshSoon; interval: 600; onTriggered: status.running = true }
    Timer { interval: 2500; repeat: true; running: cc.visible; triggeredOnStart: true; onTriggered: status.running = true }

    PopupSurface {
        growFrom: Item.TopRight
        anchors.fill: parent
        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: R.Theme.pad
            spacing: R.Theme.gap
            visible: !cc.page
            opacity: 1 - cc.pageShift * 0.6
            transform: Translate { x: cc.page ? 0 : -cc.pageShift * 30 }

            RowLayout {
                Layout.fillWidth: true
                spacing: R.Theme.gap
                R.Glass {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 170
                    Layout.preferredHeight: conn.implicitHeight + 12
                    ColumnLayout {
                        id: conn
                        anchors.fill: parent; anchors.margins: 6
                        spacing: 2
                        R.ToggleRow {
                            Layout.fillWidth: true
                            iconName: "network-wireless-symbolic"
                            title: qsTr("Wi-Fi")
                            available: cc.flag("wifi_available")
                            on: cc.flag("wifi_on")
                            status: !available ? qsTr("No Wi-Fi") : (!on ? qsTr("Off")
                                    : (cc.st.wifi_name || (cc.flag("net_wired") ? qsTr("Wired") : qsTr("Not connected"))))
                            onToggled: cc.act(["wifi", on ? "off" : "on"])
                            expandable: available
                            onExpanded: cc.openPage("wifi")
                        }
                        R.ToggleRow {
                            Layout.fillWidth: true
                            iconName: "network-bluetooth-symbolic"
                            title: qsTr("Bluetooth")
                            available: cc.flag("bt_available")
                            on: cc.flag("bt_on")
                            status: !available ? qsTr("Not available") : (!on ? qsTr("Off") : (cc.st.bt_devices || qsTr("On")))
                            onToggled: cc.act(["bluetooth", on ? "off" : "on"])
                            expandable: available
                            onExpanded: cc.openPage("bluetooth")
                        }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: false          // layouts stretch by default; keep this column narrow
                    Layout.preferredWidth: 128
                    spacing: R.Theme.gap
                    R.Glass {
                        Layout.fillWidth: true; Layout.preferredHeight: 56
                        R.ToggleRow {
                            anchors.fill: parent; anchors.margins: 6
                            iconName: "notifications-disabled-symbolic"
                            title: qsTr("Focus")
                            on: cc.flag("focus_on")
                            status: on ? qsTr("On") : ""
                            onToggled: cc.act(["focus", on ? "off" : "on"])
                        }
                    }
                    R.Glass {
                        Layout.fillWidth: true; Layout.preferredHeight: 56
                        R.ToggleRow {
                            anchors.fill: parent; anchors.margins: 6
                            iconName: on ? "weather-clear-night-symbolic" : "weather-clear-symbolic"
                            title: on ? qsTr("Dark") : qsTr("Light")
                            status: qsTr("Appearance")
                            on: cc.st.dark !== "0"
                            onToggled: { appearance.running = true; refreshSoon.restart(); }
                        }
                    }
                }
            }
            R.Glass {
                Layout.fillWidth: true; Layout.preferredHeight: 68
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: R.Theme.pad; spacing: 8
                    RowLayout {
                        R.SectionLabel { text: qsTr("Display") }
                        Item { Layout.fillWidth: true }
                        Text {
                            visible: !cc.flag("brightness_available")
                            text: qsTr("Use the display's buttons")
                            color: R.Theme.tertiaryText
                            font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeCaption
                        }
                    }
                    R.PillSlider {
                        Layout.fillWidth: true
                        available: cc.flag("brightness_available")
                        iconName: "brightness-high-symbolic"
                        value: parseInt(cc.st.brightness || "50") / 100
                        onReleased: v => cc.act(["brightness", String(Math.round(v * 100))])
                    }
                }
            }
            R.Glass {
                Layout.fillWidth: true; Layout.preferredHeight: 68
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: R.Theme.pad; spacing: 8
                    RowLayout {
                        Layout.fillWidth: true
                        R.SectionLabel { text: qsTr("Sound") }
                        Item { Layout.fillWidth: true }
                        Text {      // choose the output (speakers, headphones, HDMI, Bluetooth)
                            text: "›"; color: R.Theme.secondaryText; font.pixelSize: 16
                            MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: cc.openPage("sound") }
                        }
                    }
                    R.PillSlider {
                        Layout.fillWidth: true
                        available: cc.flag("sound_available")
                        iconName: cc.flag("muted") ? "audio-volume-muted-symbolic" : "audio-volume-high-symbolic"
                        value: parseInt(cc.st.volume || "50") / 100
                        onReleased: v => cc.act(["volume", String(Math.round(v * 100))])
                    }
                }
            }
            NowPlaying { Layout.fillWidth: true }
            R.Glass {
                Layout.fillWidth: true; Layout.preferredHeight: 52
                visible: UPower.displayDevice && UPower.displayDevice.isLaptopBattery
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 10
                    Kirigami.Icon {
                        implicitWidth: 20; implicitHeight: 20; isMask: true; color: R.Theme.text
                        source: UPower.displayDevice && UPower.displayDevice.state === UPowerDeviceState.Charging
                                ? "battery-full-charging-symbolic" : "battery-good-symbolic"
                    }
                    R.SectionLabel { Layout.fillWidth: true; text: qsTr("Battery") }
                    Text {
                        readonly property real p: UPower.displayDevice ? UPower.displayDevice.percentage : 0
                        text: Math.round(p <= 1 ? p * 100 : p) + "%"
                        color: R.Theme.secondaryText
                        font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody
                    }
                }
            }
        }

        // Expanded module: Wi-Fi networks or Bluetooth devices
        ColumnLayout {
            id: detail
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            anchors.margins: R.Theme.pad
            spacing: 6
            visible: !!cc.page
            opacity: 1 - cc.pageShift * 0.6
            transform: Translate { x: cc.pageShift * 30 }
            RowLayout {
                Layout.fillWidth: true
                MouseArea {
                    implicitWidth: 28; implicitHeight: 28
                    onClicked: cc.page = ""
                    Rectangle { anchors.fill: parent; radius: 14; color: R.Theme.bubble }
                    Text { anchors.centerIn: parent; text: "‹"; color: R.Theme.text; font.pixelSize: 18 }
                }
                Text {
                    Layout.fillWidth: true; leftPadding: 6
                    text: cc.page === "wifi" ? qsTr("Wi-Fi") : cc.page === "sound" ? qsTr("Sound Output") : qsTr("Bluetooth")
                    color: R.Theme.text
                    font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody + 2; font.weight: Font.Bold
                }
                Rectangle {     // the module's own switch
                    visible: cc.page !== "sound"
                    readonly property bool on: cc.page === "wifi" ? cc.flag("wifi_on") : cc.flag("bt_on")
                    implicitWidth: 38; implicitHeight: 22; radius: 11
                    color: on ? R.Theme.accent : R.Theme.sliderTrack
                    Behavior on color { ColorAnimation { duration: R.Theme.fast } }
                    Rectangle {
                        width: 18; height: 18; radius: 9; y: 2; color: "white"
                        x: parent.on ? parent.width - width - 2 : 2
                        Behavior on x { SpringAnimation { spring: 5; damping: 0.38; epsilon: 0.3 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { cc.act([cc.page === "wifi" ? "wifi" : "bluetooth", parent.on ? "off" : "on"]); listRefresh.restart(); }
                    }
                    Timer { id: listRefresh; interval: 1500; onTriggered: cc.openPage(cc.page) }
                }
            }
            R.SectionLabel {
                Layout.topMargin: 4
                text: cc.page === "wifi" ? qsTr("Networks") : cc.page === "sound" ? qsTr("Output") : qsTr("My Devices")
                color: R.Theme.secondaryText
                font.pixelSize: R.Theme.sizeCaption
            }
            Text {
                visible: cc.listRows.length === 0
                text: lister.running ? qsTr("Searching…") : (cc.page === "wifi" ? qsTr("No networks found") : cc.page === "sound" ? qsTr("No outputs") : qsTr("No paired devices"))
                color: R.Theme.tertiaryText
                font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody
                Layout.leftMargin: 6
            }
            Repeater {
                model: cc.listRows
                MouseArea {
                    id: net
                    required property var modelData
                    readonly property bool wifi: cc.page === "wifi"
                    readonly property bool sound: cc.page === "sound"
                    readonly property bool active: wifi ? modelData[0] === "*" : modelData[2] === "1"
                    readonly property string name: wifi ? modelData[1] : modelData[1]
                    Layout.fillWidth: true
                    implicitHeight: 34
                    hoverEnabled: true
                    readonly property bool secured: wifi && (modelData[3] || "--") !== "--" && modelData[3] !== ""
                    readonly property bool known: wifi && modelData[4] === "1"
                    onClicked: {
                        if (sound) { cc.act(["sink", modelData[0]]); listRefresh.restart(); return; }
                        if (wifi && !active && secured && !known) { cc.askSsid = name; cc.joinError = ""; return; }
                        cc.act(wifi ? ["wifi-connect", name] : ["bt-device", modelData[0]]);
                        listRefresh.restart();
                    }
                    Rectangle { anchors.fill: parent; radius: R.Theme.radiusHighlight; color: R.Theme.hover; opacity: net.containsMouse ? 1 : 0 }
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 8; spacing: 10
                        Rectangle {
                            implicitWidth: 26; implicitHeight: 26; radius: 13
                            color: net.active ? R.Theme.accent : R.Theme.bubble
                            Kirigami.Icon {
                                anchors.centerIn: parent; width: 14; height: 14; isMask: true
                                color: net.active ? R.Theme.textOnAccent : R.Theme.text
                                source: !net.wifi ? (net.sound ? "audio-speakers-symbolic" : "network-bluetooth-symbolic")
                                    : parseInt(net.modelData[2]) > 66 ? "network-wireless-signal-excellent-symbolic"
                                    : parseInt(net.modelData[2]) > 33 ? "network-wireless-signal-good-symbolic"
                                    : "network-wireless-signal-weak-symbolic"
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: net.name
                            color: R.Theme.text; elide: Text.ElideRight
                            font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody
                            font.weight: net.active ? Font.DemiBold : Font.Normal
                        }
                        Kirigami.Icon {
                            visible: net.wifi && (net.modelData[3] || "").length > 0 && net.modelData[3] !== "--"
                            implicitWidth: 12; implicitHeight: 12; isMask: true; color: R.Theme.tertiaryText
                            source: "object-locked-symbolic"
                        }
                    }
                }
            }
            // Ravana password prompt for a new secured network
            ColumnLayout {
                Layout.fillWidth: true
                visible: cc.page === "wifi" && cc.askSsid.length > 0
                spacing: 8
                Text {
                    Layout.leftMargin: 6
                    text: qsTr("Password for “%1”").arg(cc.askSsid)
                    color: R.Theme.text
                    font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody; font.weight: Font.DemiBold
                }
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 30; radius: 15
                    color: R.Theme.dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)
                    border.width: 1; border.color: R.Theme.blockBorder
                    TextInput {
                        id: wifiPassword
                        anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "\u25cf"
                        color: R.Theme.text
                        font.family: R.Theme.fontFamily; font.pixelSize: 13
                        Keys.onReturnPressed: cc.join()
                        Keys.onEscapePressed: cc.askSsid = ""
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter; x: 14
                        visible: !wifiPassword.text
                        text: qsTr("Password"); color: R.Theme.tertiaryText
                        font.family: R.Theme.fontFamily; font.pixelSize: 13
                    }
                }
                Text {
                    visible: cc.joinError.length > 0
                    Layout.leftMargin: 6
                    text: cc.joinError
                    color: R.Theme.accent
                    font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeCaption
                }
                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    R.PushButton { text: qsTr("Cancel"); onClicked: { cc.askSsid = ""; wifiPassword.text = ""; } }
                    R.PushButton { text: joiner.running ? qsTr("Joining…") : qsTr("Join"); primary: true; onClicked: cc.join() }
                }
            }

            MenuSeparator { Layout.fillWidth: true }
            MouseArea {
                Layout.fillWidth: true; implicitHeight: 28
                onClicked: { cc.visible = false; settingsRun.running = true; }
                Process { id: settingsRun; command: ["systemsettings", cc.page === "wifi" ? "kcm_networkmanagement" : cc.page === "sound" ? "kcm_pulseaudio" : "kcm_bluetooth"] }
                Text {
                    anchors.verticalCenter: parent.verticalCenter; leftPadding: 6
                    text: cc.page === "wifi" ? qsTr("Wi-Fi Settings…") : cc.page === "sound" ? qsTr("Sound Settings…") : qsTr("Bluetooth Settings…")
                    color: R.Theme.text
                    font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody
                }
            }
        }
    }
}
