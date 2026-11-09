// Copyright (c) 2026 Ravana OS. All rights reserved.
// One notification banner: app icon, app name, time, bold title, body, actions.
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import org.kde.kirigami as Kirigami
import org.ravana.ui as R

Item {
    id: card
    property var notification
    signal done()

    readonly property bool critical: notification && notification.urgency === 2   // Critical
    readonly property date arrived: new Date()
    implicitHeight: body.implicitHeight + 28

    // slide in from the right, slide out when done
    property real shown: 0
    Component.onCompleted: shown = 1
    Behavior on shown { NumberAnimation { duration: R.Theme.bloom + 80; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
    opacity: Math.min(1, shown * 1.4)
    scale: 0.96 + 0.04 * Math.min(1, shown)
    transform: Translate { x: (1 - card.shown) * 60 }

    function close() { shown = 0; leave.start(); }
    Timer { id: leave; interval: R.Theme.normal; onTriggered: card.done() }
    Timer {
        interval: card.notification && card.notification.expireTimeout > 0 ? card.notification.expireTimeout : 5500
        running: !card.critical && !hover.hovered
        onTriggered: card.close()
    }
    Connections { target: card.notification; function onClosed() { card.close(); } }

    R.Material {
        anchors.fill: parent
        anchors.margins: 6
        kind: "regular"
        radius: R.Theme.radiusCard
        shadow: true
    }
    HoverHandler { id: hover }

    RowLayout {
        id: body
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 18
        spacing: 12

        Kirigami.Icon {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 36; Layout.preferredHeight: 36
            source: card.notification ? (card.notification.image || card.notification.appIcon || "dialog-information") : ""
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: card.notification ? (card.notification.appName || "").toUpperCase() : ""
                    color: R.Theme.secondaryText
                    font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeCaption; font.letterSpacing: 0.4
                    elide: Text.ElideRight
                }
                Text {
                    text: hover.hovered ? "" : Qt.formatTime(card.arrived, Qt.locale().timeFormat(Locale.ShortFormat))
                    color: R.Theme.secondaryText
                    font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeCaption
                }
                Text {    // close
                    visible: hover.hovered
                    text: "✕"
                    color: R.Theme.secondaryText
                    font.pixelSize: 12
                    MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: { card.notification.dismiss(); card.close(); } }
                }
            }
            Text {
                Layout.fillWidth: true
                text: card.notification ? card.notification.summary : ""
                color: R.Theme.text
                font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody; font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: card.notification ? card.notification.body : ""
                textFormat: Text.StyledText
                color: R.Theme.text
                opacity: 0.85
                font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }
            RowLayout {
                visible: card.notification && card.notification.actions.length > 0 && hover.hovered
                spacing: 6
                Repeater {
                    model: card.notification ? card.notification.actions : []
                    Rectangle {
                        required property var modelData
                        implicitWidth: label.implicitWidth + 22; implicitHeight: 26
                        radius: 13
                        color: R.Theme.bubble
                        Text {
                            id: label; anchors.centerIn: parent
                            text: modelData.text
                            color: R.Theme.text
                            font.family: R.Theme.fontFamily; font.pixelSize: 12
                        }
                        MouseArea { anchors.fill: parent; onClicked: { modelData.invoke(); card.close(); } }
                    }
                }
            }
        }
    }

    MouseArea {    // click the card: default action if any, then close
        anchors.fill: parent
        z: -1
        onClicked: {
            const acts = card.notification ? card.notification.actions : [];
            const def = acts.find(a => a.identifier === "default");
            if (def) def.invoke();
            card.close();
        }
    }
}
