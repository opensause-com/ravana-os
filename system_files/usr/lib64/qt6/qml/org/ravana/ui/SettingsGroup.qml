// Copyright (c) 2026 Ravana OS. All rights reserved.
// An inset group of rows (macOS System Settings style): rounded block, hairlines between rows.
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: g
    property string title: ""
    property string footer: ""
    default property alias rows: box.data
    Layout.fillWidth: true
    spacing: 6
    Text {
        textFormat: Text.PlainText
        visible: g.title.length > 0
        text: g.title
        Layout.leftMargin: 4
        color: Theme.text
        font.family: Theme.fontFamily; font.pixelSize: Theme.sizeBody; font.weight: Font.DemiBold
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: box.implicitHeight
        radius: 10
        color: Theme.dark ? Qt.rgba(1, 1, 1, 0.05) : "#ffffff"
        border.width: 1
        border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.07)
        ColumnLayout { id: box; anchors.left: parent.left; anchors.right: parent.right; spacing: 0 }
    }
    Text {
        textFormat: Text.PlainText
        visible: g.footer.length > 0
        text: g.footer
        Layout.fillWidth: true; Layout.leftMargin: 4
        wrapMode: Text.Wrap
        color: Theme.secondaryText
        font.family: Theme.fontFamily; font.pixelSize: Theme.sizeCaption
    }
}
