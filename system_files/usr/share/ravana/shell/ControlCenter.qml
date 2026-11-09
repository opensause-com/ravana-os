// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana Control Center (Ravana Shell): Wi-Fi, Bluetooth, Focus, Appearance,
// display brightness and sound. Backend: /usr/libexec/ravana-cc.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import org.ravana.ui as R

PopupWindow {
    id: cc
    property var barWindow
    anchor.window: barWindow
    anchor.rect.x: barWindow ? barWindow.width - implicitWidth + 6 : 0
    anchor.rect.y: barWindow ? barWindow.height : 0
    grabFocus: true
    visible: false
    color: "transparent"
    implicitWidth: 340 + 28
    implicitHeight: col.implicitHeight + 2 * R.Theme.pad + 28

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
    Process { id: appearance; command: ["/usr/libexec/ravana-appearance", "toggle"] }
    function act(args) { action.command = ["/usr/libexec/ravana-cc"].concat(args); action.running = true; refreshSoon.restart(); }
    Timer { id: refreshSoon; interval: 600; onTriggered: status.running = true }
    Timer { interval: 2500; repeat: true; running: cc.visible; triggeredOnStart: true; onTriggered: status.running = true }

    PopupSurface {
        anchors.fill: parent
        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: R.Theme.pad
            spacing: R.Theme.gap

            RowLayout {
                Layout.fillWidth: true
                spacing: R.Theme.gap
                R.Glass {
                    Layout.fillWidth: true
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
                        }
                        R.ToggleRow {
                            Layout.fillWidth: true
                            iconName: "network-bluetooth-symbolic"
                            title: qsTr("Bluetooth")
                            available: cc.flag("bt_available")
                            on: cc.flag("bt_on")
                            status: !available ? qsTr("Not available") : (!on ? qsTr("Off") : (cc.st.bt_devices || qsTr("On")))
                            onToggled: cc.act(["bluetooth", on ? "off" : "on"])
                        }
                    }
                }
                ColumnLayout {
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
                visible: cc.flag("brightness_available")
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: R.Theme.pad; spacing: 8
                    R.SectionLabel { text: qsTr("Display") }
                    R.PillSlider {
                        Layout.fillWidth: true
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
                    R.SectionLabel { text: qsTr("Sound") }
                    R.PillSlider {
                        Layout.fillWidth: true
                        available: cc.flag("sound_available")
                        iconName: cc.flag("muted") ? "audio-volume-muted-symbolic" : "audio-volume-high-symbolic"
                        value: parseInt(cc.st.volume || "50") / 100
                        onReleased: v => cc.act(["volume", String(Math.round(v * 100))])
                    }
                }
            }
        }
    }
}
