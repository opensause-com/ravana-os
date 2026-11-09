// Copyright (c) 2026 Ravana OS. All rights reserved.
// One settings row: icon (optional), label, detail, then a control or a chevron.
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.ravana.ui as R

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
        color: R.Theme.hover
        visible: area.containsMouse
    }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12; anchors.rightMargin: 12
        spacing: 10
        Kirigami.Icon {
            visible: row.icon.length > 0
            implicitWidth: 18; implicitHeight: 18
            source: row.icon; isMask: true; color: R.Theme.text
        }
        Text {
            Layout.fillWidth: true
            text: row.label
            elide: Text.ElideRight
            color: R.Theme.text
            font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody
        }
        Text {
            visible: row.detail.length > 0
            text: row.detail
            Layout.maximumWidth: row.width * 0.55
            elide: Text.ElideMiddle
            color: R.Theme.secondaryText
            font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody
        }
        Item { id: slot; implicitWidth: childrenRect.width; implicitHeight: childrenRect.height; Layout.alignment: Qt.AlignVCenter }
        Text {
            visible: row.chevron
            text: "›"
            color: R.Theme.tertiaryText
            font.pixelSize: 18
        }
    }
    Rectangle {      // hairline between rows
        visible: !row.last
        anchors.bottom: parent.bottom
        anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 12
        height: 1
        color: R.Theme.dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.07)
    }
}
