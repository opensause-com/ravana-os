// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana Notification Center: slides in from the right edge. Today's widgets
// (date, calendar, now playing, battery) above notifications grouped by app.
// Opens from the clock in the menu bar, ⌘N-style IPC, or (phase 4) a two-finger edge swipe.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import org.kde.kirigami as Kirigami
import org.ravana.ui as R

PanelWindow {
    id: nc
    property var history: null                  // the notification server's tracked notifications
    visible: false
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ravana-notification-center"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    property real shown: 0
    Behavior on shown { NumberAnimation { duration: R.Theme.normal + 80; easing.type: Easing.OutCubic } }
    function toggle() { if (visible) hide(); else { visible = true; shown = 1; } }
    function hide() { shown = 0; closer.restart(); }
    Timer { id: closer; interval: R.Theme.normal + 80; onTriggered: nc.visible = false }

    readonly property var notes: history ? history.values : []
    readonly property var groups: {
        const g = [];
        notes.slice().reverse().forEach(n => {
            const key = n.appName || qsTr("Other");
            let grp = g.find(x => x.app === key);
            if (!grp) { grp = { app: key, icon: n.appIcon, items: [] }; g.push(grp); }
            grp.items.push(n);
        });
        return g;
    }

    MouseArea { anchors.fill: parent; onClicked: nc.hide() }

    Flickable {
        id: panel
        width: 380
        anchors.top: parent.top; anchors.bottom: parent.bottom
        anchors.topMargin: 36; anchors.bottomMargin: 8
        x: parent.width - width - 8 + (1 - nc.shown) * (width + 16)
        opacity: Math.min(1, nc.shown * 1.5)
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.DragAndOvershootBounds
        focus: true
        Keys.onEscapePressed: nc.hide()
        MouseArea { width: panel.width; height: Math.max(panel.height, col.implicitHeight); onClicked: {} }

        ColumnLayout {
            id: col
            width: panel.width
            spacing: 10

            // Date header
            ColumnLayout {
                Layout.leftMargin: 6
                spacing: 0
                SystemClock { id: clock; precision: SystemClock.Minutes }
                Text {
                    text: Qt.formatDate(clock.date, "dddd")
                    color: R.Theme.dark ? "white" : "#1d1d1f"; style: R.Theme.dark ? Text.Raised : Text.Normal; styleColor: Qt.rgba(0, 0, 0, 0.3)
                    font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody; font.weight: Font.DemiBold
                }
                Text {
                    text: Qt.formatDate(clock.date, "d MMMM")
                    color: R.Theme.dark ? "white" : "#1d1d1f"; style: R.Theme.dark ? Text.Raised : Text.Normal; styleColor: Qt.rgba(0, 0, 0, 0.3)
                    font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeDisplay; font.weight: Font.Bold
                }
            }

            Card { Layout.fillWidth: true; implicitHeight: calendar.implicitHeight; CalendarCard { id: calendar; anchors.fill: parent; color: "transparent"; border.width: 0 } }
            Card {
                Layout.fillWidth: true; implicitHeight: 76
                visible: nowPlaying.visible
                NowPlaying { id: nowPlaying; anchors.fill: parent; color: "transparent"; border.width: 0 }
            }
            Card {
                Layout.fillWidth: true; implicitHeight: 64
                visible: UPower.displayDevice && UPower.displayDevice.isLaptopBattery
                RowLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 12
                    Kirigami.Icon {
                        implicitWidth: 28; implicitHeight: 28; isMask: true; color: R.Theme.text
                        source: UPower.displayDevice && UPower.displayDevice.state === UPowerDeviceState.Charging
                                ? "battery-full-charging-symbolic" : "battery-good-symbolic"
                    }
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Battery")
                        color: R.Theme.text
                        font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody; font.weight: Font.DemiBold
                    }
                    Text {
                        readonly property real p: UPower.displayDevice ? UPower.displayDevice.percentage : 0
                        text: Math.round(p <= 1 ? p * 100 : p) + "%"
                        color: R.Theme.secondaryText
                        font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeLarge; font.weight: Font.DemiBold
                    }
                }
            }

            // Notifications, grouped by app
            RowLayout {
                Layout.fillWidth: true; Layout.leftMargin: 6; Layout.rightMargin: 6; Layout.topMargin: 6
                Text {
                    Layout.fillWidth: true
                    text: qsTr("Notifications")
                    color: R.Theme.dark ? "white" : "#1d1d1f"; style: R.Theme.dark ? Text.Raised : Text.Normal; styleColor: Qt.rgba(0, 0, 0, 0.3)
                    font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody; font.weight: Font.Bold
                }
                Rectangle {
                    visible: nc.notes.length > 0
                    implicitWidth: clearAll.implicitWidth + 20; implicitHeight: 24; radius: 12
                    color: R.Theme.glassTint("thick")
                    Text { id: clearAll; anchors.centerIn: parent; text: qsTr("Clear All"); color: R.Theme.text
                           font.family: R.Theme.fontFamily; font.pixelSize: 12 }
                    MouseArea { anchors.fill: parent; onClicked: nc.notes.slice().forEach(n => n.dismiss()) }
                }
            }
            Card {
                Layout.fillWidth: true; implicitHeight: 60
                visible: nc.notes.length === 0
                Text {
                    anchors.centerIn: parent
                    text: qsTr("No Notifications")
                    color: R.Theme.secondaryText
                    font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody
                }
            }
            Repeater {
                model: nc.groups
                Card {
                    id: group
                    required property var modelData
                    property bool expanded: false
                    Layout.fillWidth: true
                    implicitHeight: gcol.implicitHeight + 20
                    ColumnLayout {
                        id: gcol
                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 8
                        RowLayout {
                            Layout.fillWidth: true
                            Kirigami.Icon { implicitWidth: 18; implicitHeight: 18; source: group.modelData.icon || "dialog-information" }
                            Text {
                                Layout.fillWidth: true
                                text: group.modelData.app.toUpperCase() + (group.modelData.items.length > 1 ? "  ·  " + group.modelData.items.length : "")
                                color: R.Theme.secondaryText
                                font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeCaption; font.letterSpacing: 0.4
                            }
                            Text {
                                text: "✕"; color: R.Theme.secondaryText; font.pixelSize: 12
                                MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: group.modelData.items.forEach(n => n.dismiss()) }
                            }
                        }
                        Repeater {
                            model: group.expanded ? group.modelData.items : group.modelData.items.slice(0, 4)
                            MouseArea {
                                id: item
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: icol.implicitHeight
                                onClicked: {
                                    const d = modelData.actions.find(a => a.identifier === "default");
                                    if (d) d.invoke();
                                    nc.hide();
                                }
                                ColumnLayout {
                                    id: icol
                                    width: parent.width
                                    spacing: 1
                                    Text {
                                        Layout.fillWidth: true
                                        text: item.modelData.summary
                                        color: R.Theme.text; elide: Text.ElideRight
                                        font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody; font.weight: Font.DemiBold
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        visible: text.length > 0
                                        text: item.modelData.body
                                        textFormat: Text.StyledText
                                        color: R.Theme.text; opacity: 0.85
                                        wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                                        font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody
                                    }
                                }
                            }
                        }
                        Text {      // stack: show the rest / show less
                            visible: group.modelData.items.length > 4
                            text: group.expanded ? qsTr("Show less") : qsTr("Show %1 more").arg(group.modelData.items.length - 4)
                            color: R.Theme.accent
                            font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeCaption; font.weight: Font.DemiBold
                            MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: group.expanded = !group.expanded }
                        }
                    }
                }
            }
        }
    }

    // A frosted card on the wallpaper
    component Card: Rectangle {
        radius: R.Theme.radiusCard
        color: R.Theme.glassTint("thick")
        border.width: 1
        border.color: R.Theme.glassRim
    }
}
