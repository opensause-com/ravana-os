// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana menu bar:  crown  App name  ............  Control Center  search  Mon 9 Nov  8:41 PM
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
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

    GlassBackdrop {
        anchors.fill: parent
        radius: 0
        tint: 0.35
        origin: Qt.point(0, 0)
        screenSize: Qt.size(bar.screen.width, bar.screen.height)
    }

    TaskManager.TasksModel {
        id: tasks
        groupMode: TaskManager.TasksModel.GroupDisabled
        filterMinimized: true
    }
    readonly property string appName: {
        const i = tasks.activeTask;
        return (i && i.valid) ? (tasks.data(i, TaskManager.AbstractTasksModel.AppName) || "") : "";
    }

    function run(cmd) { runner.command = ["sh", "-c", cmd]; runner.running = true; }
    Process { id: runner }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 12
        spacing: 14

        BarButton {
            id: crown
            Layout.preferredWidth: 30
            icon: "ravana-logo"
            iconIsMask: false
            onClicked: ravanaMenu.visible = !ravanaMenu.visible
        }
        Text {
            text: bar.appName || "Ravana"
            color: R.Theme.text
            font.family: R.Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Bold
            renderType: Text.NativeRendering
        }
        Item { Layout.fillWidth: true }

        BarButton { icon: "ravana-controlcenter"; onClicked: controlCenter.visible = !controlCenter.visible }
        BarButton {
            icon: "search-symbolic"
            onClicked: bar.run("dbus-send --session --type=method_call --dest=org.kde.krunner /App org.kde.krunner.App.toggleDisplay")
        }
        Text {
            id: clockText
            color: R.Theme.text
            font.family: R.Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
            renderType: Text.NativeRendering
            SystemClock { id: clock; precision: SystemClock.Minutes }
            text: Qt.formatDateTime(clock.date, "ddd d MMM") + "   " + Qt.formatTime(clock.date, Qt.locale().timeFormat(Locale.ShortFormat))
        }
    }

    RavanaMenu { id: ravanaMenu; anchorItem: crown; barWindow: bar }
    ControlCenter { id: controlCenter; barWindow: bar }

    // `qs ipc -p /usr/share/ravana/shell call menu toggle` / `call controlcenter toggle`
    readonly property bool primary: bar.screen === Quickshell.screens[0]
    IpcHandler { target: "menu"; enabled: bar.primary; function toggle(): void { ravanaMenu.visible = !ravanaMenu.visible; } }
    IpcHandler { target: "controlcenter"; enabled: bar.primary; function toggle(): void { controlCenter.visible = !controlCenter.visible; } }
}
