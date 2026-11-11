// Copyright (c) 2026 Ravana OS. All rights reserved.
// One settings row: icon (optional), label, detail, then a control or a chevron.
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: row
    property string label
    property string detail: ""
    property string icon: ""
    property bool chevron: false
    property bool last: false
    default property alias control: slot.data
    signal clicked()
    Layout.fillWidth: true
    implicitHeight: Math.max(40, slot.implicitHeight + 16)

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: row.chevron
        enabled: row.chevron
        onClicked: row.clicked()
    }
    Rectangle {
        anchors.fill: parent; anchors.margins: 2
        radius: 8
        color: Theme.hover
        visible: area.containsMouse
    }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12; anchors.rightMargin: 12
        spacing: 10
        Kirigami.Icon {
            visible: row.icon.length > 0
            implicitWidth: 18; implicitHeight: 18
            source: row.icon; isMask: true; color: Theme.text
        }
        Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            text: row.label
            elide: Text.ElideRight
            color: Theme.text
            font.family: Theme.fontFamily; font.pixelSize: Theme.sizeBody
        }
        Text {
            textFormat: Text.PlainText
            visible: row.detail.length > 0
            text: row.detail
            Layout.maximumWidth: row.width * 0.55
            elide: Text.ElideMiddle
            color: Theme.secondaryText
            font.family: Theme.fontFamily; font.pixelSize: Theme.sizeBody
        }
        Item { id: slot; implicitWidth: childrenRect.width; implicitHeight: childrenRect.height; Layout.alignment: Qt.AlignVCenter }
        Text {
            textFormat: Text.PlainText
            visible: row.chevron
            text: "›"
            color: Theme.tertiaryText
            font.pixelSize: 18
        }
    }
    Rectangle {      // hairline between rows
        visible: !row.last
        anchors.bottom: parent.bottom
        anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 12
        height: 1
        color: Theme.dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.07)
    }
}
