// Copyright (c) 2026 Ravana OS. All rights reserved.
// The crown's system menu: About, Settings, App Store, Software Update, Force Quit,
// Sleep, Restart, Shut Down, Lock Screen, Log Out.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import org.ravana.ui as R

PopupWindow {
    id: menu
    property Item anchorItem
    property var barWindow
    anchor.item: anchorItem
    anchor.rect.y: anchorItem ? anchorItem.height + 2 : 0
    anchor.rect.x: -14
    grabFocus: Quickshell.env("RAVANA_SHELL_TEST") !== "1"   // no pointer in the cloud test
    visible: false
    color: "transparent"
    implicitWidth: 262
    implicitHeight: list.implicitHeight + 28 + 12

    readonly property string logout: "dbus-send --session --type=method_call --dest=org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt."
    function run(cmd) { menu.visible = false; runner.command = ["sh", "-c", cmd]; runner.running = true; }
    Process { id: runner }

    PopupSurface {
        growFrom: Item.TopLeft
        anchors.fill: parent
        radius: R.Theme.radiusMedium
        ColumnLayout {
            id: list
            anchors.fill: parent
            anchors.margins: 6
            spacing: 0
            MenuEntry { text: qsTr("About This Computer"); onActivated: menu.run("ravana-settings about") }
            MenuSeparator {}
            MenuEntry { text: qsTr("System Settings…"); onActivated: menu.run("ravana-settings") }
            MenuEntry { text: qsTr("App Store…"); onActivated: menu.run("gtk-launch io.github.kolunmi.Bazaar || plasma-discover") }
            MenuEntry { text: qsTr("Software Update…"); onActivated: menu.run("ravana-settings update") }
            MenuSeparator {}
            MenuEntry { text: qsTr("Force Quit…"); onActivated: menu.run("dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.killWindow") }
            MenuSeparator {}
            MenuEntry { text: qsTr("Sleep"); onActivated: menu.run("systemctl suspend") }
            MenuEntry { text: qsTr("Restart…"); onActivated: menu.run("qs ipc -p /usr/share/ravana/shell call power ask restart") }
            MenuEntry { text: qsTr("Shut Down…"); onActivated: menu.run("qs ipc -p /usr/share/ravana/shell call power ask shutdown") }
            MenuSeparator {}
            MenuEntry { text: qsTr("Lock Screen"); onActivated: menu.run("loginctl lock-session") }
            MenuEntry { text: qsTr("Log Out…"); onActivated: menu.run("qs ipc -p /usr/share/ravana/shell call power ask logout") }
        }
    }
}
