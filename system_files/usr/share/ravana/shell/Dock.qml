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

    // Desktop & Dock settings (Settings app writes ~/.config/ravana-dock-settings.json)
    property var cfg: ({ size: 50, magnify: true, autohide: false })
    FileView {
        id: cfgFile
        path: Quickshell.env("HOME") + "/.config/ravana-dock-settings.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { try { const c = JSON.parse(text()); dock.cfg = Object.assign({ size: 50, magnify: true, autohide: false }, c); } catch (e) {} }
    }
    readonly property int iconSize: Math.max(32, Math.min(80, cfg.size || 50))
    readonly property int cell: iconSize + 10
    readonly property real magnify: cfg.magnify === false ? 0 : 0.55     // extra size at the pointer
    readonly property int pad: 8
    readonly property int baseHeight: iconSize + 2 * pad + 8
    readonly property int bottomGap: 8

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "ravana-dock"
    anchors { bottom: true }
    margins.bottom: bottomGap
    exclusiveZone: cfg.autohide ? 0 : baseHeight
    color: "transparent"
    // tall enough for magnified icons; only the dock itself takes clicks
    implicitWidth: row.width + 2 * pad + 40
    implicitHeight: baseHeight + iconSize * magnify + 34
    mask: Region { item: dock.revealed ? glass : edge }

    // auto-hide: slides away, comes back when the pointer touches the bottom edge
    readonly property bool revealed: !cfg.autohide || hover.hovered || edgeHover.hovered || menuOpen || stay.running
    Timer { id: stay; interval: 600 }
    onRevealedChanged: if (revealed) stay.restart()
    property real hideOffset: revealed ? 0 : baseHeight + bottomGap + 12
    Behavior on hideOffset { NumberAnimation { duration: R.Theme.normal; easing.type: Easing.OutCubic } }
    Item {
        id: edge
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 3
        HoverHandler { id: edgeHover }
    }

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
        "applications:org.quickshell.desktop"
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

    // ---- Downloads stack: newest files in a glass grid ----
    property var recent: []
    Process {
        id: recentReader
        command: ["sh", "-c", 'd="$(xdg-user-dir DOWNLOAD 2>/dev/null)"; [ -z "$d" ] || [ "$d" = "$HOME" ] && d="$HOME/Downloads"; ls -t1 -- "$d" 2>/dev/null | head -12 | while IFS= read -r f; do printf "%s\t%s\n" "$d/$f" "$f"; done']
        stdout: StdioCollector {
            onStreamFinished: {
                dock.recent = text.split("\n").filter(l => l).map(l => l.split("\t"));
                if (dock.stackPending) { dock.stackPending = false; stack.visible = true; }   // open once the list is in
            }
        }
    }
    property bool stackPending: false
    function openDownloads(item) {
        if (stack.visible) { stack.visible = false; return; }
        stack.anchorItem = item;
        stackPending = true;
        recentReader.running = true;
    }
    Process { id: opener }
    DownloadsStack {
        id: stack
        visible: false
        files: dock.recent
        onOpenFile: f => { opener.command = ["xdg-open", f]; opener.running = true; }   // no shell: names can't run code
        onOpenFolder: dock.run('d="$(xdg-user-dir DOWNLOAD 2>/dev/null)"; [ -z "$d" ] || [ "$d" = "$HOME" ] && d="$HOME/Downloads"; dolphin "$d"')
    }

    // ---- right-click menu ----
    property bool menuOpen: dockMenu.visible || stack.visible
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
        function close(): void { dockMenu.visible = false; stack.visible = false; }
        function showDownloads(): string {
            dock.openDownloads(downloads);
            return "downloads stack requested";
        }
    }

    function run(cmd) { runner.command = ["sh", "-c", cmd]; runner.running = true; }
    Process { id: runner }

    R.Material {
        id: glass
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -dock.hideOffset
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
        anchors.bottomMargin: dock.pad + 6 - dock.hideOffset
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
            id: downloads
            host: dock
            iconSource: "folder-download"
            label: qsTr("Downloads")
            onClicked: dock.openDownloads(downloads)
        }

        DockIcon {
            host: dock
            iconSource: "user-trash"
            label: qsTr("Trash")
            onClicked: dock.run("dolphin trash:/")
        }
    }
}
