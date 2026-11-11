// Copyright (c) 2026 Ravana OS. All rights reserved.
// Downloads stack: the newest files in a glass grid above the Dock (like macOS's Grid view).
// Pictures show as thumbnails; everything else shows its file-type icon.
import QtQuick
import QtQuick.Layouts
import Quickshell
import org.kde.kirigami as Kirigami
import org.ravana.ui as R

PopupWindow {
    id: pop
    property Item anchorItem
    property var files: []            // [[path, name], …]
    signal openFile(string path)
    signal openFolder()

    anchor.item: anchorItem
    anchor.rect.x: anchorItem ? anchorItem.width / 2 - implicitWidth / 2 : 0
    anchor.rect.y: -implicitHeight - 6
    grabFocus: Quickshell.env("RAVANA_SHELL_TEST") !== "1"
    color: "transparent"
    implicitWidth: 4 * 96 + 28 + 24
    // one fixed size (title, 3 rows of 4, button): a popup must not resize while open
    implicitHeight: 3 * 92 + 120

    function iconFor(name) {
        const ext = (name.split(".").pop() || "").toLowerCase();
        if (["zip", "tar", "gz", "xz", "7z", "rar", "zst"].includes(ext)) return "package-x-generic";
        if (["pdf"].includes(ext)) return "application-pdf";
        if (["mp3", "flac", "wav", "ogg", "m4a"].includes(ext)) return "audio-x-generic";
        if (["mp4", "mkv", "webm", "mov", "avi"].includes(ext)) return "video-x-generic";
        if (["iso", "img"].includes(ext)) return "media-optical";
        if (["rpm", "deb", "flatpakref", "appimage"].includes(ext)) return "application-x-executable";
        if (["txt", "md", "log"].includes(ext)) return "text-x-generic";
        if (["doc", "docx", "odt"].includes(ext)) return "x-office-document";
        if (["xls", "xlsx", "ods", "csv"].includes(ext)) return "x-office-spreadsheet";
        return name.indexOf(".") < 0 ? "folder" : "text-x-generic";
    }
    function isPicture(name) { return /\.(png|jpe?g|webp|gif|bmp|avif)$/i.test(name); }

    PopupSurface {
        anchors.fill: parent
        growFrom: Item.Bottom
        radius: R.Theme.radiusCard
        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8
            Text {
                textFormat: Text.PlainText
                text: qsTr("Downloads")
                color: R.Theme.text
                font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody; font.weight: Font.Bold
            }
            Text {
                textFormat: Text.PlainText
                visible: pop.files.length === 0
                text: qsTr("Nothing downloaded yet")
                color: R.Theme.secondaryText
                font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeCaption
            }
            Grid {
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                columns: 4
                Repeater {
                    model: pop.files
                    MouseArea {
                        id: cell
                        required property var modelData
                        width: 96; height: 92
                        hoverEnabled: true
                        onClicked: { pop.visible = false; pop.openFile(modelData[0]); }
                        Rectangle { anchors.fill: parent; anchors.margins: 2; radius: 10; color: R.Theme.hover; opacity: cell.containsMouse ? 1 : 0 }
                        Image {
                            id: thumb
                            visible: pop.isPicture(cell.modelData[1]) && status === Image.Ready
                            anchors.horizontalCenter: parent.horizontalCenter; y: 8
                            width: 52; height: 52
                            source: pop.isPicture(cell.modelData[1]) ? "file://" + cell.modelData[0] : ""
                            sourceSize: Qt.size(104, 104)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        Kirigami.Icon {
                            visible: !thumb.visible
                            anchors.horizontalCenter: parent.horizontalCenter; y: 8
                            width: 52; height: 52
                            source: pop.isPicture(cell.modelData[1]) ? "image-x-generic" : pop.iconFor(cell.modelData[1])
                        }
                        Text {
                            textFormat: Text.PlainText
                            anchors.horizontalCenter: parent.horizontalCenter; y: 66
                            width: 88
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideMiddle
                            text: cell.modelData[1]
                            color: R.Theme.text
                            font.family: R.Theme.fontFamily; font.pixelSize: 11
                        }
                    }
                }
            }
            Item { Layout.fillHeight: true }     // files at the top, button at the bottom
            R.PushButton {
                Layout.alignment: Qt.AlignRight
                text: qsTr("Open in Files")
                onClicked: { pop.visible = false; pop.openFolder(); }
            }
        }
    }
}
