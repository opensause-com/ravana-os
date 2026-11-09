// Copyright (c) 2026 Ravana OS. All rights reserved.
// Right-click menu for a dock item: Open / New Window, Keep in Dock, Show All Windows, Quit.
import QtQuick
import QtQuick.Layouts
import Quickshell
import org.ravana.ui as R

PopupWindow {
    id: pop
    property Item anchorItem
    property var entries: []          // [{ label, action, separator? }]
    signal chosen(string action)

    anchor.item: anchorItem
    anchor.rect.x: anchorItem ? anchorItem.width / 2 - implicitWidth / 2 : 0
    anchor.rect.y: -implicitHeight - 4
    grabFocus: Quickshell.env("RAVANA_SHELL_TEST") !== "1"
    color: "transparent"
    implicitWidth: Math.max(190, col.implicitWidth + 12) + 28
    implicitHeight: col.implicitHeight + 12 + 28

    PopupSurface {
        anchors.fill: parent
        growFrom: Item.Bottom
        radius: R.Theme.radiusMenu
        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 6
            spacing: 0
            Repeater {
                model: pop.entries
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
                            implicitWidth: label.implicitWidth + 40
                            hoverEnabled: true
                            onClicked: { pop.visible = false; pop.chosen(modelData.action); }
                            Rectangle {
                                anchors.fill: parent
                                radius: R.Theme.radiusHighlight
                                color: R.Theme.accent
                                opacity: row.containsMouse ? 1 : 0
                            }
                            Text {
                                id: label
                                x: 12; anchors.verticalCenter: parent.verticalCenter
                                text: (modelData.checked ? "✓  " : "") + modelData.label
                                color: row.containsMouse ? R.Theme.textOnAccent : R.Theme.text
                                font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody
                            }
                        }
                    }
                }
            }
        }
    }
}
