// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana dock: Launchpad | pinned + open apps | divider | Trash.
// Hover magnification, a dot under open apps, name bubble, Ravana pulse while launching.
// Window list from KDE's task model (KWin), which also places minimize animations.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import org.kde.taskmanager as TaskManager
import org.kde.kirigami as Kirigami
import org.ravana.ui as R

PanelWindow {
    id: dock
    signal launchpadRequested()

    readonly property int iconSize: 50
    readonly property int cell: iconSize + 10
    readonly property real magnify: 0.55          // extra size at the pointer
    readonly property int pad: 8
    readonly property int baseHeight: iconSize + 2 * pad + 8
    readonly property int bottomGap: 8

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "ravana-dock"
    anchors { bottom: true }
    margins.bottom: bottomGap
    exclusiveZone: baseHeight
    color: "transparent"
    // tall enough for magnified icons; only the dock itself takes clicks
    implicitWidth: row.width + 2 * pad + 40
    implicitHeight: baseHeight + iconSize * magnify + 34
    mask: Region { item: glass }

    property real mouseX: -1000
    function scaleFor(itemCenterX) {
        if (mouseX < -500) return 1;
        const d = Math.abs(itemCenterX - mouseX) / (cell * 2.2);
        return 1 + magnify * Math.max(0, Math.cos(Math.min(d, 1) * Math.PI / 2));
    }

    TaskManager.VirtualDesktopInfo { id: desktops }
    TaskManager.ActivityInfo { id: activities }
    TaskManager.TasksModel {
        id: tasks
        sortMode: TaskManager.TasksModel.SortManual
        groupMode: TaskManager.TasksModel.GroupApplications
        groupInline: false
        separateLaunchers: false
        launchInPlace: true
        hideActivatedLaunchers: true
        filterByActivity: true
        activity: activities.currentActivity
        launcherList: [
            "applications:org.kde.dolphin.desktop",
            "preferred://browser",
            "applications:steam.desktop",
            "applications:org.kde.konsole.desktop",
            "applications:systemsettings.desktop"
        ]
    }

    function run(cmd) { runner.command = ["sh", "-c", cmd]; runner.running = true; }
    Process { id: runner }

    GlassBackdrop {
        id: glass
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: row.width + 2 * dock.pad
        height: dock.baseHeight
        radius: 22
        tint: 0.30
        origin: Qt.point((dock.screen.width - width) / 2, dock.screen.height - dock.bottomGap - height)
        screenSize: Qt.size(dock.screen.width, dock.screen.height)
    }

    // Passive pointer tracking over the whole dock (icons on top don't block it)
    Item {
        anchors.fill: glass
        HoverHandler {
            id: hover
            onPointChanged: dock.mouseX = hovered ? point.position.x + glass.x : -1000
            onHoveredChanged: if (!hovered) dock.mouseX = -1000
        }
    }

    Row {
        id: row
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: dock.pad + 6
        spacing: 0

        DockIcon {
            dock: dock
            iconSource: "ravana-launchpad"
            label: qsTr("Launchpad")
            onClicked: dock.launchpadRequested()
        }

        Repeater {
            model: tasks
            DockIcon {
                required property int index
                required property var model
                dock: dock
                iconSource: model.decoration
                label: model.display || model.AppName || ""
                running: !model.IsLauncher && !model.IsStartup
                launching: model.IsStartup || model.IsDemandingAttention
                onClicked: tasks.requestActivate(tasks.makeModelIndex(index))
                onMiddleClicked: tasks.requestNewInstance(tasks.makeModelIndex(index))
            }
        }

        Item {   // divider before Trash
            width: dock.cell * 0.4; height: dock.iconSize
            Rectangle {
                anchors.centerIn: parent
                width: 1; height: dock.iconSize * 0.72
                color: R.Theme.text; opacity: 0.25
            }
        }

        DockIcon {
            dock: dock
            iconSource: "user-trash"
            label: qsTr("Trash")
            onClicked: dock.run("dolphin trash:/")
        }
    }
}
