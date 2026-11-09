// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana logout screen (power button, Ctrl+Alt+Del, "Leave…"): a centred glass alert
// that blooms in. It replaces only the look of Plasma's LogoutControls.qml; every action
// goes through the same hostRoot calls Plasma's own screen uses (Logout.qml is unchanged).
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents
import org.kde.coreaddons as KCoreAddons
import org.kde.kirigami as Kirigami
import org.kde.breeze.components
import org.kde.plasma.private.sessions

Item {
    id: controls
    anchors.fill: parent

    readonly property Item hostRoot: parent
    readonly property bool showAllOptions: sdtype === ShutdownType.ShutdownTypeDefault
    readonly property bool dark: true

    // Ravana bloom
    property real reveal: 0
    opacity: Math.min(1, reveal * 1.6)
    onHostRootChanged: bloom.restart()
    NumberAnimation { id: bloom; target: controls; property: "reveal"; from: 0; to: 1
        duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.15 }

    readonly property string title: {
        if (sdtype === ShutdownType.ShutdownTypeReboot)
            return i18nd("plasma_shell_org.kde.plasma.desktop", "Restart") + "?";
        if (sdtype === ShutdownType.ShutdownTypeHalt)
            return i18nd("plasma_shell_org.kde.plasma.desktop", "Shut Down") + "?";
        if (sdtype === ShutdownType.ShutdownTypeNone)
            return i18nd("plasma_shell_org.kde.plasma.desktop", "Log Out") + "?";
        return "";
    }

    Item {
        id: alert
        anchors.centerIn: parent
        width: Math.max(320, buttons.implicitWidth + 48)
        height: col.implicitHeight + 44
        scale: 0.92 + 0.08 * controls.reveal

        RectangularShadow {
            anchors.fill: card; radius: card.radius
            blur: 48; offset: Qt.vector2d(0, 18); color: Qt.rgba(0, 0, 0, 0.5)
        }
        Rectangle {
            id: card
            anchors.fill: parent
            radius: 18
            color: Qt.rgba(0.15, 0.14, 0.16, 0.86)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.14)
            MouseArea { anchors.fill: parent }       // clicks on the card don't cancel
        }

        ColumnLayout {
            id: col
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            anchors.margins: 22
            spacing: 12

            Image {
                Layout.alignment: Qt.AlignHCenter
                source: "file:///usr/share/icons/hicolor/128x128/apps/ravana-logo-white.png"
                sourceSize: Qt.size(56, 56)
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: controls.showAllOptions ? "Ravana OS" : controls.title
                color: "#f5f5f7"
                font.family: "Inter"; font.pixelSize: 15; font.weight: Font.Bold
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                visible: controls.hostRoot && controls.hostRoot.countingDown
                text: softwareUpdatePending
                      ? i18ndc("plasma_shell_org.kde.plasma.desktop", "@info", "Updates will be installed first.")
                        + "  " + Math.max(0, Math.ceil(controls.hostRoot ? controls.hostRoot.remainingTime : 0)) + " s"
                      : "If you do nothing, this happens automatically in "
                        + Math.max(0, Math.ceil(controls.hostRoot ? controls.hostRoot.remainingTime : 0)) + " seconds."
                color: Qt.rgba(1, 1, 1, 0.58)
                font.family: "Inter"; font.pixelSize: 12
            }

            // Actions (same conditions and calls as Plasma's screen)
            RowLayout {
                id: buttons
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                spacing: 8
                RavanaButton {
                    label: i18nd("plasma_shell_org.kde.plasma.desktop", "&Cancel").replace("&", "")
                    onActivated: controls.hostRoot.cancelRequested()
                }
                RavanaButton {
                    label: i18ndc("plasma_shell_org.kde.plasma.desktop", "Suspend to RAM", "Slee&p").replace("&", "")
                    visible: spdMethods.SuspendState && controls.showAllOptions
                    onActivated: controls.hostRoot.sleepRequested()
                }
                RavanaButton {
                    label: i18nd("plasma_shell_org.kde.plasma.desktop", "&Hibernate").replace("&", "")
                    visible: spdMethods.HibernateState && controls.showAllOptions
                    onActivated: controls.hostRoot.hibernateRequested()
                }
                RavanaButton {
                    label: i18nd("plasma_shell_org.kde.plasma.desktop", "&Log Out").replace("&", "")
                    visible: canLogout && (sdtype === ShutdownType.ShutdownTypeNone || controls.showAllOptions)
                    primary: sdtype === ShutdownType.ShutdownTypeNone
                    onActivated: controls.hostRoot.logoutRequested()
                }
                RavanaButton {
                    label: i18nd("plasma_shell_org.kde.plasma.desktop", "&Restart").replace("&", "")
                    visible: maysd && (sdtype === ShutdownType.ShutdownTypeReboot || controls.showAllOptions)
                    primary: sdtype === ShutdownType.ShutdownTypeReboot
                    onActivated: softwareUpdatePending ? controls.hostRoot.rebootUpdateRequested() : controls.hostRoot.rebootRequested()
                }
                RavanaButton {
                    label: i18nd("plasma_shell_org.kde.plasma.desktop", "&Shut Down").replace("&", "")
                    visible: maysd && (sdtype === ShutdownType.ShutdownTypeHalt || controls.showAllOptions)
                    primary: sdtype === ShutdownType.ShutdownTypeHalt || controls.showAllOptions
                    onActivated: softwareUpdatePending ? controls.hostRoot.haltUpdateRequested() : controls.hostRoot.haltRequested()
                }
            }
        }
    }

    // Enter = the highlighted (red) action
    focus: true
    Keys.onReturnPressed: controls.hostRoot.currentAction ? (controls.hostRoot.currentAction)() : controls.hostRoot.cancelRequested()
    Keys.onEnterPressed: controls.hostRoot.currentAction ? (controls.hostRoot.currentAction)() : controls.hostRoot.cancelRequested()

    component RavanaButton: Rectangle {
        id: btn
        property string label
        property bool primary: false
        signal activated()
        implicitWidth: Math.max(82, txt.implicitWidth + 28)
        implicitHeight: 32
        radius: 9
        color: primary ? "#d21f3c" : Qt.rgba(1, 1, 1, area.containsMouse ? 0.18 : 0.12)
        opacity: area.pressed ? 0.75 : 1
        Text {
            id: txt
            anchors.centerIn: parent
            text: btn.label
            color: "white"
            font.family: "Inter"; font.pixelSize: 13
            font.weight: btn.primary ? Font.DemiBold : Font.Normal
        }
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: btn.activated() }
    }
}
