/*
 * Ravana dock apps: the macOS-style row of pinned and open apps.
 * - pinned apps and open apps share one row (an open app takes its pin's place)
 * - a small dot under every open app, none under pinned-only apps
 * - icons lift slightly under the pointer; the app's name appears above it
 * - launching apps pulse (Ravana motion) with a red ember dot until their window appears
 * - right-click: New Window, Keep in Dock / Remove from Dock, Quit
 * - a thin divider at the end separates apps from Trash, like macOS
 * Built on KDE's task model (org.kde.taskmanager), the same one Plasma's task manager uses.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents3
import org.kde.taskmanager as TaskManager
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    readonly property int dotSpace: Math.max(5, Math.round(height * 0.09))
    readonly property int iconSize: Math.max(16, Math.round(height - dotSpace * 2 - 4))
    readonly property int cell: iconSize + Math.round(iconSize * 0.18)

    Layout.minimumWidth: row.implicitWidth
    Layout.preferredWidth: row.implicitWidth
    Layout.maximumWidth: row.implicitWidth
    Layout.fillHeight: true

    TaskManager.VirtualDesktopInfo { id: desktopInfo }
    TaskManager.ActivityInfo { id: activityInfo }

    TaskManager.TasksModel {
        id: tasksModel
        sortMode: TaskManager.TasksModel.SortManual
        groupMode: TaskManager.TasksModel.GroupApplications
        groupInline: false
        separateLaunchers: false
        launchInPlace: true
        hideActivatedLaunchers: false
        filterByActivity: true
        activity: activityInfo.currentActivity
        filterByScreen: false
        filterByCurrentVirtualDesktop: false

        Component.onCompleted: launcherList = Plasmoid.configuration.launchers
        onLauncherListChanged: Plasmoid.configuration.launchers = launcherList
    }

    function isPinned(url) {
        return url && tasksModel.launcherPosition(url) >= 0;
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: 0

        Repeater {
            id: repeater
            model: tasksModel

            delegate: Item {
                id: task
                required property int index
                required property var model

                width: root.cell
                height: row.height

                readonly property bool running: !model.IsLauncher && !model.IsStartup
                readonly property bool hovered: mouse.containsMouse
                property int cycle: 0

                function publishGeometry() {
                    const p = task.mapToGlobal(0, 0);
                    tasksModel.requestPublishDelegateGeometry(tasksModel.makeModelIndex(task.index),
                        Qt.rect(p.x, p.y, task.width, task.height), task);
                }
                onXChanged: publishGeometry()
                Component.onCompleted: Qt.callLater(publishGeometry)

                Kirigami.Icon {
                    id: icon
                    width: root.iconSize
                    height: root.iconSize
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: (parent.height - root.dotSpace - height) / 2 - lift
                    source: task.model.decoration
                    active: false
                    scale: task.hovered ? 1.12 : 1.0
                    transformOrigin: Item.Bottom
                    property real lift: task.hovered ? root.iconSize * 0.08 : 0
                    // Ravana pulse: a launching (or attention-seeking) app breathes gently
                    property real pulse: 0
                    transform: Scale {
                        origin.x: icon.width / 2
                        origin.y: icon.height
                        xScale: 1 + icon.pulse * 0.07
                        yScale: 1 + icon.pulse * 0.07
                    }

                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on lift { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                    SequentialAnimation on pulse {
                        running: task.model.IsStartup || task.model.IsDemandingAttention
                        loops: Animation.Infinite
                        alwaysRunToEnd: true
                        NumberAnimation { to: 1; duration: 420; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0; duration: 420; easing.type: Easing.InOutSine }
                    }
                }

                // Open-app dot
                Rectangle {
                    width: Math.max(4, Math.round(root.iconSize * 0.075))
                    height: width
                    radius: width / 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Math.max(1, Math.round(root.dotSpace / 2 - height / 2) + 1)
                    color: (task.model.IsStartup || task.model.IsDemandingAttention) ? "#ff3d55" : Kirigami.Theme.textColor
                    opacity: task.running || task.model.IsStartup ? (task.model.IsStartup ? 0.6 + icon.pulse * 0.4 : 0.85) : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // App name above the icon on hover (the tooltip area watches the mouse area inside it)
                PlasmaCore.ToolTipArea {
                    anchors.fill: parent
                    mainText: task.model.display || task.model.AppName || ""
                    location: PlasmaCore.Types.BottomEdge
                    interactive: false

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        onClicked: mouseEvent => {
                            const idx = tasksModel.makeModelIndex(task.index);
                            if (mouseEvent.button === Qt.MiddleButton) {
                                tasksModel.requestNewInstance(idx);
                            } else if (mouseEvent.button === Qt.RightButton) {
                                contextMenu.openFor(task);
                            } else if (task.model.ChildCount > 1) {
                                // Several windows: bring them up one by one on repeated clicks
                                const child = tasksModel.makeModelIndex(task.index, task.cycle % task.model.ChildCount);
                                tasksModel.requestActivate(child);
                                task.cycle++;
                            } else {
                                tasksModel.requestActivate(idx);
                            }
                        }
                    }
                }
            }
        }

        // Divider before Trash
        Item {
            width: Math.round(root.iconSize * 0.45)
            height: row.height
            Rectangle {
                anchors.centerIn: parent
                width: 1
                height: Math.round(root.iconSize * 0.72)
                color: Kirigami.Theme.textColor
                opacity: 0.28
            }
        }
    }

    PlasmaExtras.Menu {
        id: contextMenu
        property Item target: null
        property var targetModel: null
        placement: PlasmaExtras.Menu.TopPosedLeftAlignedPopup

        function openFor(item) {
            target = item;
            targetModel = item.model;
            visualParent = item;
            const url = item.model.LauncherUrlWithoutIcon;
            newWindow.visible = !item.model.IsLauncher;
            keep.text = root.isPinned(url) ? i18n("Remove from Dock") : i18n("Keep in Dock");
            keep.visible = !!url && url.toString().length > 0;
            quit.visible = !item.model.IsLauncher && !item.model.IsStartup;
            openRelative();
        }

        PlasmaExtras.MenuItem {
            id: newWindow
            text: i18n("New Window")
            icon: "window-new"
            onClicked: tasksModel.requestNewInstance(tasksModel.makeModelIndex(contextMenu.target.index))
        }
        PlasmaExtras.MenuItem {
            id: keep
            icon: "pin"
            onClicked: {
                const url = contextMenu.targetModel.LauncherUrlWithoutIcon;
                if (root.isPinned(url)) {
                    tasksModel.requestRemoveLauncher(url);
                } else {
                    tasksModel.requestAddLauncher(url);
                }
            }
        }
        PlasmaExtras.MenuItem { separator: true }
        PlasmaExtras.MenuItem {
            id: quit
            text: i18n("Quit")
            icon: "application-exit"
            onClicked: tasksModel.requestClose(tasksModel.makeModelIndex(contextMenu.target.index))
        }
    }
}
