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
    function takeKeys() { col.cur = -1; col.moveTo(0); col.forceActiveFocus(); }
    onVisibleChanged: if (!visible) closing(); else { col.cur = -1; col.forceActiveFocus(); }

    anchor.item: anchorItem
    anchor.rect.x: side ? (anchorItem ? anchorItem.width + 2 : 0) : -10
    anchor.rect.y: side ? -6 : (anchorItem ? anchorItem.height + 1 : 0)
    grabFocus: Quickshell.env("RAVANA_SHELL_TEST") !== "1"
    color: "transparent"
    implicitWidth: Math.max(220, col.implicitWidth + 12) + 28
    implicitHeight: col.implicitHeight + 12 + 28

    function click(id) {
        Quickshell.execDetached(["/usr/libexec/ravana-appmenu", "click", pop.service, pop.objectPath, String(id)]);
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
            // keyboard: up/down move, Return chooses, Right opens a submenu, Left/Esc go back
            focus: true
            property int cur: -1
            readonly property var rows: Array.from(children).map(c => c.item)
                                        .filter(r => r && r.keyFocus !== undefined && r.enabled)
            function moveTo(i) {
                const n = rows.length; if (!n) return;
                cur = (i + n) % n;
                rows.forEach((r, k) => r.keyFocus = (k === cur));
            }
            Keys.onDownPressed: moveTo(cur + 1)
            Keys.onUpPressed: moveTo(cur < 0 ? -1 : cur - 1)
            Keys.onReturnPressed: if (cur >= 0) rows[cur].activate()
            Keys.onEnterPressed: if (cur >= 0) rows[cur].activate()
            Keys.onRightPressed: if (cur >= 0 && rows[cur].modelData.submenu) rows[cur].activate()
            Keys.onLeftPressed: if (pop.side) pop.visible = false
            Keys.onEscapePressed: pop.visible = false
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
                            property bool keyFocus: false
                            readonly property bool lit: containsMouse || keyFocus
                            function activate() { modelData.submenu ? sub.open(true) : pop.click(modelData.id); }
                            onClicked: activate()
                            onContainsMouseChanged: if (containsMouse && modelData.submenu) sub.open(false)
                            Rectangle {
                                anchors.fill: parent
                                radius: R.Theme.radiusHighlight
                                color: R.Theme.accent
                                opacity: row.lit && row.enabled ? 1 : 0
                            }
                            Text {    // check mark
                                x: 8; anchors.verticalCenter: parent.verticalCenter
                                visible: modelData.checked
                                text: "✓"
                                color: row.lit ? R.Theme.textOnAccent : R.Theme.text
                                font.pixelSize: 12
                            }
                            Text {
                                id: label
                                x: 24; anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: !row.enabled ? R.Theme.tertiaryText : row.lit ? R.Theme.textOnAccent : R.Theme.text
                                font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody
                            }
                            Text {
                                id: keys
                                anchors.right: parent.right; anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.submenu ? "›" : modelData.shortcut
                                color: row.lit && row.enabled ? R.Theme.textOnAccent : R.Theme.tertiaryText
                                font.family: R.Theme.fontFamily; font.pixelSize: modelData.submenu ? 16 : R.Theme.sizeBody
                            }
                            QtObject {
                                id: sub
                                property var popup: null
                                // created from the file: a QML type can't contain itself directly
                                function open(withKeys) {
                                    if (!popup) {
                                        popup = Qt.createComponent("AppMenuPopup.qml").createObject(row, {
                                            items: modelData.children, service: pop.service, objectPath: pop.objectPath,
                                            anchorItem: row, side: true });
                                        if (!popup) return;
                                        popup.triggered.connect(() => { pop.visible = false; pop.triggered(); });
                                        pop.closing.connect(() => { if (sub.popup) sub.popup.visible = false; });
                                    }
                                    popup.visible = true;
                                    if (withKeys) popup.takeKeys();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
