// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana menu bar:
//   crown  App  File Edit View …              battery  Wi-Fi  Control Center  search  Mon 9 Nov 8:41 PM
// Frosted, with a fine hairline divider. App menus come from the focused app over D-Bus.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import org.kde.taskmanager as TaskManager
import org.kde.kirigami as Kirigami
import org.ravana.ui as R

PanelWindow {
    id: bar
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "ravana-menubar"
    anchors { top: true; left: true; right: true }
    implicitHeight: 30
    exclusiveZone: implicitHeight
    color: "transparent"

    // Frosted bar + hairline divider
    Rectangle {
        anchors.fill: parent
        color: R.Theme.dark ? Qt.rgba(0.07, 0.06, 0.08, 0.42) : Qt.rgba(0.99, 0.99, 1.0, 0.55)
    }
    Rectangle {
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 1
        color: R.Theme.dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.10)
    }

    // ---- focused app: name + menu address ----
    TaskManager.TasksModel {
        id: tasks
        groupMode: TaskManager.TasksModel.GroupDisabled
        filterMinimized: true
    }
    function activeRole(role) {
        const i = tasks.activeTask;
        return (i && i.valid) ? (tasks.data(i, role) || "") : "";
    }
    readonly property string appName: activeRole(TaskManager.AbstractTasksModel.AppName)
    readonly property string menuService: activeRole(TaskManager.AbstractTasksModel.ApplicationMenuServiceName)
    readonly property string menuPath: activeRole(TaskManager.AbstractTasksModel.ApplicationMenuObjectPath)
    property var menus: []

    Process {
        id: menuReader
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const t = JSON.parse(text);
                    bar.menus = (t.children || []).filter(c => c.label && !c.separator);
                } catch (e) { bar.menus = []; }
            }
        }
    }
    function reloadMenus() {
        bar.menus = [];
        if (!menuService || !menuPath) return;
        menuReader.command = ["/usr/libexec/ravana-appmenu", "layout", menuService, menuPath];
        menuReader.running = true;
    }
    onMenuServiceChanged: reloadMenus()
    onMenuPathChanged: reloadMenus()

    // ---- status (shared SystemStatus from the shell; one set of checks for all screens) ----
    property var sys
    readonly property var net: sys ? sys.net : ({})
    readonly property var kbd: sys ? sys.kbd : ({})
    readonly property bool micInUse: sys ? sys.micInUse : false
    property bool focusOn: false            // Focus (Do Not Disturb), from the notification server

    readonly property bool hasBattery: UPower.displayDevice && UPower.displayDevice.isLaptopBattery

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]); }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 12
        spacing: 0

        BarButton {
            id: crown
            Layout.preferredWidth: 32
            icon: R.Theme.dark ? "ravana-logo-white" : "ravana-logo"
            iconIsMask: false
            onClicked: ravanaMenu.visible = !ravanaMenu.visible
        }
        BarText {
            text: bar.appName || "Ravana"
            bold: true
        }
        Repeater {
            model: bar.menus
            BarText {
                id: title
                required property var modelData
                text: modelData.label
                active: openMenu.visible && openMenu.owner === title
                onClicked: {
                    if (openMenu.visible && openMenu.owner === title) { openMenu.visible = false; return; }
                    openMenu.owner = title;
                    openMenu.items = modelData.children;
                    openMenu.anchorItem = title;
                    openMenu.visible = true;
                }
                // macOS: once a menu is open, sliding to the next title opens that one
                onHovered: if (openMenu.visible && openMenu.owner !== title) clicked()
            }
        }
        Item { Layout.fillWidth: true }

        // menu-bar extras from apps' tray icons (on the primary screen, like macOS)
        Repeater {
            model: bar.primary ? SystemTray.items : []
            TrayItem { barWindow: bar }
        }

        Rectangle {     // microphone in use
            visible: bar.micInUse
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 8
            implicitWidth: 7; implicitHeight: 7; radius: 3.5
            color: "#ff9f0a"
        }
        BarButton {     // Focus is on
            visible: bar.focusOn
            icon: "weather-clear-night-symbolic"
            onClicked: controlCenter.visible = !controlCenter.visible
        }
        Text {      // keyboard layout, click to switch
            visible: parseInt(bar.kbd.count || "0") > 1
            text: (bar.kbd.current || "").toUpperCase()
            color: R.Theme.barText
            font.family: R.Theme.fontFamily; font.pixelSize: 12; font.weight: Font.DemiBold
            rightPadding: 8
            MouseArea {
                anchors.fill: parent
                onClicked: { bar.run("busctl --user call org.kde.keyboard /Layouts org.kde.KeyboardLayouts switchToNextLayout"); if (bar.sys) bar.sys.refreshKbd(); }
            }
        }
        Text {
            visible: bar.hasBattery
            text: bar.hasBattery ? Math.round(UPower.displayDevice.percentage * (UPower.displayDevice.percentage <= 1 ? 100 : 1)) + "%" : ""
            color: R.Theme.barText
            font.family: R.Theme.fontFamily; font.pixelSize: 12
            rightPadding: 4
        }
        BarButton {
            visible: bar.hasBattery
            icon: UPower.displayDevice && UPower.displayDevice.state === UPowerDeviceState.Charging
                  ? "battery-full-charging-symbolic" : "battery-good-symbolic"
        }
        BarButton {
            icon: bar.net.net_wired === "1" ? "network-wired-symbolic"
                : (bar.net.wifi_on === "1" && bar.net.wifi_name) ? "network-wireless-signal-excellent-symbolic"
                : bar.net.wifi_on === "1" ? "network-wireless-offline-symbolic" : "network-wireless-disconnected-symbolic"
            onClicked: controlCenter.visible = !controlCenter.visible
        }
        BarButton { icon: "ravana-controlcenter"; onClicked: controlCenter.visible = !controlCenter.visible }
        BarButton {
            icon: "search-symbolic"
            onClicked: bar.run("qs ipc -p /usr/share/ravana/shell call spotlight toggle")
        }
        Text {
            id: clockText
            leftPadding: 8
            color: R.Theme.barText
            font.family: R.Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
            SystemClock { id: clock; precision: SystemClock.Minutes }
            text: Qt.formatDateTime(clock.date, "ddd d MMM") + "   " + Qt.formatTime(clock.date, Qt.locale().timeFormat(Locale.ShortFormat))
            // the clock opens Notification Center
            MouseArea { anchors.fill: parent; onClicked: bar.run("qs ipc -p /usr/share/ravana/shell call notifications toggle") }
        }
    }

    AppMenuPopup {
        id: openMenu
        property Item owner: null
        visible: false
        service: bar.menuService
        objectPath: bar.menuPath
    }

    RavanaMenu { id: ravanaMenu; anchorItem: crown; barWindow: bar }
    ControlCenter { id: controlCenter; barWindow: bar }

    // `qs ipc -p /usr/share/ravana/shell call menu toggle` / `call controlcenter toggle` / `call appmenu open`
    readonly property bool primary: bar.screen === Quickshell.screens[0]
    IpcHandler { target: "menu"; enabled: bar.primary; function toggle(): void { ravanaMenu.visible = !ravanaMenu.visible; } }
    IpcHandler {
        target: "controlcenter"; enabled: bar.primary
        function toggle(): void { controlCenter.visible = !controlCenter.visible; }
        function page(name: string): void { controlCenter.showPage(name); }
        function join(ssid: string): void { controlCenter.showPage("wifi"); controlCenter.askSsid = ssid; }
    }
    IpcHandler {
        target: "appmenu"; enabled: bar.primary
        function first(): string {
            if (!bar.menus.length) return "no menus (" + bar.menuService + " " + bar.menuPath + ")";
            openMenu.owner = null; openMenu.items = bar.menus[0].children; openMenu.anchorItem = crown; openMenu.visible = true;
            return bar.menus.map(m => m.label).join(" ");
        }
        function close(): void { openMenu.visible = false; }
        // focused window: name | app id | launcher (tests)
        function info(): string {
            return bar.appName + " | " + bar.activeRole(TaskManager.AbstractTasksModel.AppId)
                 + " | " + bar.activeRole(TaskManager.AbstractTasksModel.LauncherUrlWithoutIcon);
        }
    }
}
