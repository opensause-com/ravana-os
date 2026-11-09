// Copyright (c) 2026 Ravana OS. All rights reserved.
// Now Playing: artwork, title, artist and transport controls for the active
// media player (any MPRIS app: Spotify, Firefox, Chrome, VLC, Steam…).
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import org.kde.kirigami as Kirigami
import org.ravana.ui as R

R.Glass {
    id: np
    readonly property var player: {
        const all = Mpris.players.values;
        return all.find(p => p.isPlaying) || all[0] || null;
    }
    visible: player !== null
    implicitHeight: 76

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12
        Rectangle {
            implicitWidth: 56; implicitHeight: 56
            radius: R.Theme.radiusSmall
            color: R.Theme.bubble
            clip: true
            Image {
                anchors.fill: parent
                source: np.player ? (np.player.trackArtUrl || "") : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(112, 112)
                asynchronous: true
            }
            Kirigami.Icon {
                anchors.centerIn: parent; width: 24; height: 24
                visible: !np.player || !np.player.trackArtUrl
                source: "media-album-cover"; isMask: true; color: R.Theme.secondaryText
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                Layout.fillWidth: true
                text: np.player ? (np.player.trackTitle || np.player.identity) : ""
                color: R.Theme.text; elide: Text.ElideRight
                font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody; font.weight: Font.DemiBold
            }
            Text {
                Layout.fillWidth: true
                text: np.player ? (np.player.trackArtist || np.player.identity || "") : ""
                color: R.Theme.secondaryText; elide: Text.ElideRight
                font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeCaption
            }
        }
        Repeater {
            model: [
                { icon: "media-skip-backward-symbolic", act: "prev" },
                { icon: np.player && np.player.isPlaying ? "media-playback-pause-symbolic" : "media-playback-start-symbolic", act: "toggle" },
                { icon: "media-skip-forward-symbolic", act: "next" }
            ]
            MouseArea {
                id: btn
                required property var modelData
                implicitWidth: 28; implicitHeight: 28
                hoverEnabled: true
                onClicked: {
                    if (!np.player) return;
                    if (modelData.act === "prev") np.player.previous();
                    else if (modelData.act === "next") np.player.next();
                    else np.player.togglePlaying();
                }
                scale: pressed ? 0.85 : 1
                Behavior on scale { SpringAnimation { spring: 6; damping: 0.35; epsilon: 0.005 } }
                Rectangle { anchors.fill: parent; radius: 14; color: R.Theme.hover; opacity: btn.containsMouse ? 1 : 0 }
                Kirigami.Icon {
                    anchors.centerIn: parent; width: modelData.act === "toggle" ? 20 : 16; height: width
                    source: modelData.icon; isMask: true; color: R.Theme.text
                }
            }
        }
    }
}
