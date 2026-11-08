/*
 * Bold name of the focused app in the menu bar (macOS: " Finder  File  Edit …").
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.taskmanager as TaskManager
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    TaskManager.TasksModel {
        id: tasks
        groupMode: TaskManager.TasksModel.GroupDisabled
        filterByScreen: false
        filterMinimized: true
    }

    readonly property string appName: {
        const idx = tasks.activeTask;
        if (!idx || !idx.valid) return "";
        return tasks.data(idx, TaskManager.AbstractTasksModel.AppName) || "";
    }

    Layout.minimumWidth: label.text.length ? label.implicitWidth + Kirigami.Units.smallSpacing * 2 : 0
    Layout.preferredWidth: Layout.minimumWidth
    Layout.maximumWidth: Layout.minimumWidth
    Layout.preferredHeight: label.implicitHeight

    PlasmaComponents3.Label {
        id: label
        anchors.centerIn: parent
        text: root.appName
        font.weight: Font.Bold
        elide: Text.ElideRight
    }
}
