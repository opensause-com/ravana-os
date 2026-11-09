// Copyright (c) 2026 Ravana OS. All rights reserved.
// A menu-bar icon button with a soft rounded hover.
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.ravana.ui as R

MouseArea {
    id: b
    property string icon
    property bool iconIsMask: true
    Layout.preferredWidth: 28
    Layout.fillHeight: true
    hoverEnabled: true
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 3; anchors.bottomMargin: 3
        radius: 6
        color: R.Theme.text
        opacity: b.containsMouse ? 0.13 : 0
        Behavior on opacity { NumberAnimation { duration: R.Theme.fast } }
    }
    Kirigami.Icon {
        anchors.centerIn: parent
        width: 17; height: 17
        source: b.icon
        isMask: b.iconIsMask
        color: R.Theme.barText
    }
}
