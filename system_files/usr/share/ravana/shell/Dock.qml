// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana dock: Launchpad | pinned + open apps | divider | Trash.
// Hover magnification, a dot under open apps, name bubble, Ravana pulse while launching.
// Window list from KDE's task model (KWin), which also places minimize animations.
import QtQuick
import QtQuick.Effects
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
        launcherList: dock.defaultPins
        // Keep in Dock / Remove from Dock are remembered per user
        onLauncherListChanged: if (dock.pinsLoaded) pinsFile.setText(JSON.stringify(launcherList))
    }

    readonly property var defaultPins: [
        "applications:org.kde.dolphin.desktop",
        "preferred://browser",
        "applications:steam.desktop",
        "applications:org.kde.konsole.desktop",
        "applications:org.ravana.settings.desktop"
    ]
    property bool pinsLoaded: false
    FileView {
        id: pinsFile
        path: Quickshell.env("HOME") + "/.config/ravana-dock.json"
        blockLoading: true
        printErrors: false
    }
    Component.onCompleted: {
        try {
            const saved = JSON.parse(pinsFile.text());
            if (Array.isArray(saved)) tasks.launcherList = saved;
        } catch (e) {}
        dock.pinsLoaded = true;
    }

    // ---- right-click menu ----
    property bool menuOpen: dockMenu.visible
    property int menuIndex: -1
    function openMenu(item, index) {
        const i = tasks.makeModelIndex(index);
        const launcher = tasks.data(i, TaskManager.AbstractTasksModel.LauncherUrlWithoutIcon);
        const pinned = launcher && tasks.launcherPosition(launcher) >= 0;
        const open = !tasks.data(i, TaskManager.AbstractTasksModel.IsLauncher);
        const e = [];
        e.push({ label: open ? qsTr("New Window") : qsTr("Open"), action: "new" });
        if (open) e.push({ label: qsTr("Show All Windows"), action: "windows" });
        e.push({ separator: true });
        if (launcher) e.push({ label: qsTr("Keep in Dock"), action: pinned ? "unpin" : "pin", checked: pinned });
        if (open) { e.push({ separator: true }); e.push({ label: qsTr("Quit"), action: "quit" }); }
        dock.menuIndex = index;
        dockMenu.entries = e;
        dockMenu.anchorItem = item;
        dockMenu.visible = true;
    }
    DockMenu {
        id: dockMenu
        visible: false
        onChosen: action => {
            const i = tasks.makeModelIndex(dock.menuIndex);
            const launcher = tasks.data(i, TaskManager.AbstractTasksModel.LauncherUrlWithoutIcon);
            if (action === "new") tasks.requestNewInstance(i);
            else if (action === "windows") tasks.requestActivate(i);
            else if (action === "pin") tasks.requestAddLauncher(launcher);
            else if (action === "unpin") tasks.requestRemoveLauncher(launcher);
            else if (action === "quit") tasks.requestClose(i);
        }
    }
    // `qs ipc -p /usr/share/ravana/shell call dock menu 0` (screenshots/tests)
    IpcHandler {
        target: "dock"; enabled: dock.screen === Quickshell.screens[0]
        function menu(index: int): void {
            for (const c of row.children) if (c.taskIndex === index) { dock.openMenu(c, index); return; }
        }
        function close(): void { dockMenu.visible = false; }
    }

    function run(cmd) { runner.command = ["sh", "-c", cmd]; runner.running = true; }
    Process { id: runner }

    R.Material {
        id: glass
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: row.width + 2 * dock.pad
        height: dock.baseHeight
        kind: "regular"
        radius: 24
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
            host: dock
            iconSource: "ravana-launchpad"
            label: qsTr("Launchpad")
            onClicked: dock.launchpadRequested()
        }

        Repeater {
            model: tasks
            DockIcon {
                id: dockItem
                required property int index
                required property var model
                readonly property int taskIndex: index
                host: dock
                iconSource: model.decoration
                label: model.display || model.AppName || ""
                running: !model.IsLauncher && !model.IsStartup
                launching: model.IsStartup || model.IsDemandingAttention
                onClicked: tasks.requestActivate(tasks.makeModelIndex(index))
                onMiddleClicked: tasks.requestNewInstance(tasks.makeModelIndex(index))
                onRightClicked: dock.openMenu(dockItem, index)
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
            host: dock
            iconSource: "user-trash"
            label: qsTr("Trash")
            onClicked: dock.run("dolphin trash:/")
        }
    }
}
