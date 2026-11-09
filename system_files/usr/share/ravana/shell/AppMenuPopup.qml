// Copyright (c) 2026 Ravana OS. All rights reserved.
// One open app menu (File, Edit, …) drawn as a Ravana menu: shortcuts on the right,
// check marks, separators, submenus opening to the side.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import org.ravana.ui as R

PopupWindow {
    id: pop
    property var items: []            // children of the opened menu (from ravana-appmenu)
    property string service
    property string objectPath
    property Item anchorItem
    property bool side: false          // submenu: open to the right of anchorItem
    signal triggered()
    signal closing()
    onVisibleChanged: if (!visible) closing()

    anchor.item: anchorItem
    anchor.rect.x: side ? (anchorItem ? anchorItem.width + 2 : 0) : -10
    anchor.rect.y: side ? -6 : (anchorItem ? anchorItem.height + 1 : 0)
    grabFocus: Quickshell.env("RAVANA_SHELL_TEST") !== "1"
    color: "transparent"
    implicitWidth: Math.max(220, col.implicitWidth + 12) + 28
    implicitHeight: col.implicitHeight + 12 + 28

    Process { id: clicker }
    function click(id) {
        clicker.command = ["/usr/libexec/ravana-appmenu", "click", pop.service, pop.objectPath, String(id)];
        clicker.running = true;
        pop.visible = false;
        pop.triggered();
    }

    PopupSurface {
        anchors.fill: parent
        growFrom: pop.side ? Item.Left : Item.TopLeft
        radius: R.Theme.radiusMenu
        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 6
            spacing: 0
            Repeater {
                model: pop.items
                Loader {
                    required property var modelData
                    Layout.fillWidth: true
                    sourceComponent: modelData.separator ? sepComp : rowComp
                    Component { id: sepComp; MenuSeparator {} }
                    Component {
                        id: rowComp
                        MouseArea {
                            id: row
                            implicitHeight: 26
                            implicitWidth: label.implicitWidth + keys.implicitWidth + 70
                            hoverEnabled: true
                            enabled: modelData.enabled
                            onClicked: modelData.submenu ? sub.open() : pop.click(modelData.id)
                            onContainsMouseChanged: if (containsMouse && modelData.submenu) sub.open()
                            Rectangle {
                                anchors.fill: parent
                                radius: R.Theme.radiusHighlight
                                color: R.Theme.accent
                                opacity: row.containsMouse && row.enabled ? 1 : 0
                            }
                            Text {    // check mark
                                x: 8; anchors.verticalCenter: parent.verticalCenter
                                visible: modelData.checked
                                text: "✓"
                                color: row.containsMouse ? R.Theme.textOnAccent : R.Theme.text
                                font.pixelSize: 12
                            }
                            Text {
                                id: label
                                x: 24; anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: !row.enabled ? R.Theme.tertiaryText : row.containsMouse ? R.Theme.textOnAccent : R.Theme.text
                                font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody
                            }
                            Text {
                                id: keys
                                anchors.right: parent.right; anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.submenu ? "›" : modelData.shortcut
                                color: row.containsMouse && row.enabled ? R.Theme.textOnAccent : R.Theme.tertiaryText
                                font.family: R.Theme.fontFamily; font.pixelSize: modelData.submenu ? 16 : R.Theme.sizeBody
                            }
                            QtObject {
                                id: sub
                                property var popup: null
                                // created from the file: a QML type can't contain itself directly
                                function open() {
                                    if (!popup) {
                                        popup = Qt.createComponent("AppMenuPopup.qml").createObject(row, {
                                            items: modelData.children, service: pop.service, objectPath: pop.objectPath,
                                            anchorItem: row, side: true });
                                        if (!popup) return;
                                        popup.triggered.connect(() => { pop.visible = false; pop.triggered(); });
                                        pop.closing.connect(() => { if (sub.popup) sub.popup.visible = false; });
                                    }
                                    popup.visible = true;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
