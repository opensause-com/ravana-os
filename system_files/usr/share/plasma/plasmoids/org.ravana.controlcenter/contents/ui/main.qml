/*
 * Ravana Control Center: one place for the everyday switches, in the Ravana UI kit.
 *   [ Wi-Fi        ] [ Focus      ]
 *   [ Bluetooth    ] [ Appearance ]
 *   Display  ( brightness pill slider )
 *   Sound    ( volume pill slider     )
 *   Control Center Settings…
 * State and actions come from /usr/libexec/ravana-cc (nmcli, bluetoothctl, wpctl,
 * KDE's brightness service, Plasma's Do Not Disturb).
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.ravana.ui as R

PlasmoidItem {
    id: root

    Plasmoid.icon: "ravana-controlcenter"
    toolTipMainText: i18n("Control Center")
    toolTipSubText: i18n("Wi-Fi, Bluetooth, Focus, display and sound")

    property var st: ({})
    function flag(k) { return st[k] === "1"; }

    P5Support.DataSource {
        id: sh
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            if (source === "/usr/libexec/ravana-cc status") {
                const s = {};
                (data.stdout || "").split("\n").forEach(l => {
                    const i = l.indexOf("=");
                    if (i > 0) s[l.slice(0, i)] = l.slice(i + 1);
                });
                root.st = s;
            }
            disconnectSource(source);
        }
        function run(args) { connectSource("/usr/libexec/ravana-cc " + args); }
    }

    function refresh() { sh.run("status"); }
    function act(args) { sh.run(args); refreshSoon.restart(); }

    Timer { id: refreshSoon; interval: 600; onTriggered: root.refresh() }
    Timer { interval: 2500; repeat: true; running: root.expanded; triggeredOnStart: true; onTriggered: root.refresh() }

    compactRepresentation: MouseArea {
        id: button
        Layout.minimumWidth: Kirigami.Units.iconSizes.small + Kirigami.Units.largeSpacing
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded
        Rectangle {
            anchors.fill: parent; anchors.margins: 2; radius: 5
            color: Kirigami.Theme.textColor
            opacity: button.containsMouse || root.expanded ? 0.12 : 0
            Behavior on opacity { NumberAnimation { duration: 140 } }
        }
        Kirigami.Icon {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.small; height: width
            source: "ravana-controlcenter"
            isMask: true
            color: Kirigami.Theme.textColor
        }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 340
        Layout.preferredHeight: col.implicitHeight + 2 * R.Theme.pad
        Layout.minimumWidth: 340
        Layout.minimumHeight: Layout.preferredHeight

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
                    Layout.minimumWidth: 170
                    Layout.preferredHeight: conn.implicitHeight + 12
                    ColumnLayout {
                        id: conn
                        anchors.fill: parent; anchors.margins: 6
                        spacing: 2
                        R.ToggleRow {
                            Layout.fillWidth: true
                            iconName: "network-wireless-symbolic"
                            title: i18n("Wi-Fi")
                            available: root.flag("wifi_available")
                            on: root.flag("wifi_on")
                            status: !available ? i18n("No Wi-Fi") : (!on ? i18n("Off")
                                    : (root.st.wifi_name || (root.flag("net_wired") ? i18n("Wired") : i18n("Not connected"))))
                            onToggled: root.act("wifi " + (on ? "off" : "on"))
                        }
                        R.ToggleRow {
                            Layout.fillWidth: true
                            iconName: "network-bluetooth-symbolic"
                            title: i18n("Bluetooth")
                            available: root.flag("bt_available")
                            on: root.flag("bt_on")
                            status: !available ? i18n("Not available") : (!on ? i18n("Off") : (root.st.bt_devices || i18n("On")))
                            onToggled: root.act("bluetooth " + (on ? "off" : "on"))
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: false          // layouts stretch by default; keep this column narrow
                    Layout.preferredWidth: 128
                    spacing: R.Theme.gap
                    R.Glass {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        R.ToggleRow {
                            anchors.fill: parent; anchors.margins: 6
                            iconName: "notifications-disabled-symbolic"
                            title: i18n("Focus")
                            on: root.flag("focus_on")
                            status: on ? i18n("On") : ""
                            onToggled: root.act("focus " + (on ? "off" : "on"))
                        }
                    }
                    R.Glass {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        R.ToggleRow {
                            anchors.fill: parent; anchors.margins: 6
                            iconName: "weather-clear-night-symbolic"
                            title: i18n("Dark")
                            on: root.st.dark !== "0"
                            status: i18n("Appearance")
                            // Light mode arrives with Ravana Light; Dark stays on until then
                            available: false
                        }
                    }
                }
            }

            R.Glass {
                Layout.fillWidth: true
                Layout.preferredHeight: 68
                visible: root.flag("brightness_available")
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: R.Theme.pad
                    spacing: 8
                    R.SectionLabel { text: i18n("Display") }
                    R.PillSlider {
                        Layout.fillWidth: true
                        iconName: "brightness-high-symbolic"
                        value: (parseInt(root.st.brightness || "50")) / 100
                        onReleased: v => root.act("brightness " + Math.round(v * 100))
                    }
                }
            }

            R.Glass {
                Layout.fillWidth: true
                Layout.preferredHeight: 68
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: R.Theme.pad
                    spacing: 8
                    R.SectionLabel { text: i18n("Sound") }
                    R.PillSlider {
                        Layout.fillWidth: true
                        available: root.flag("sound_available")
                        iconName: root.flag("muted") ? "audio-volume-muted-symbolic" : "audio-volume-high-symbolic"
                        value: (parseInt(root.st.volume || "50")) / 100
                        onReleased: v => root.act("volume " + Math.round(v * 100))
                    }
                }
            }

            R.Glass {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                Text {
                    anchors.centerIn: parent
                    text: i18n("Control Center Settings…")
                    color: R.Theme.text
                    font.family: R.Theme.fontFamily
                    font.pixelSize: R.Theme.bodySize
                    renderType: Text.NativeRendering
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { root.expanded = false; sh.connectSource("systemsettings"); }
                }
            }
        }
    }
}
