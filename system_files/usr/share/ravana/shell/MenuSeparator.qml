// Copyright (c) 2026 Ravana OS. All rights reserved.
import QtQuick
import QtQuick.Layouts
import org.ravana.ui as R

Item {
    Layout.fillWidth: true
    implicitHeight: 9
    Rectangle {
        anchors.centerIn: parent
        width: parent.width - 20; height: 1
        color: R.Theme.dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.1)
    }
}
