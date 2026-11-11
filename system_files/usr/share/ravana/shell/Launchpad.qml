// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana Launchpad: blurred wallpaper, search pill, all apps in a centered grid.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import org.kde.kirigami as Kirigami
import org.ravana.ui as R

PanelWindow {
    id: pad
    visible: false
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ravana-launchpad"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    readonly property color ink: R.Theme.dark ? "white" : "#1d1d1f"
    property real shown: 0
    Behavior on shown { NumberAnimation { duration: R.Theme.normal + 60; easing.type: Easing.OutCubic } }

    function toggle() {
        if (visible) { hide(); return; }
        search.text = "";
        pages.currentIndex = 0;
        openFolder = null;
        visible = true; shown = 1;
        search.forceActiveFocus();
    }
    function hide() { shown = 0; closeTimer.restart(); }
    // Open an app; one that needs a terminal (htop, …) opens inside one
    function launch(e) {
        if (e.runInTerminal && e.command && e.command.length)
            Quickshell.execDetached(["sh", "-c", 'if command -v konsole >/dev/null; then exec konsole -e "$@"; else exec ptyxis -- "$@"; fi', "sh"].concat(Array.from(e.command)));
        else e.execute();
    }
    Timer { id: closeTimer; interval: R.Theme.normal; onTriggered: pad.visible = false }

    // Technical tools and duplicates stay out of the grid (still searchable in Spotlight)
    readonly property var hidden: R.Theme.hiddenApps
    readonly property var apps: {
        const q = search.text.trim().toLowerCase();
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay && e.name && !pad.hidden.some(h => e.name.startsWith(h)))
            .filter(e => !q || e.name.toLowerCase().includes(q)
                     || (e.genericName || "").toLowerCase().includes(q)
                     || (e.keywords || []).some(k => k.toLowerCase().includes(q)))
            .sort((a, b) => a.name.localeCompare(b.name));
    }

    // Mac-style folders: system tools live in "Utilities" (search still shows them flat)
    readonly property var keepOut: ["Dolphin", "Files", "Konsole", "System Settings", "Steam", "Lutris",
        "Bazaar", "Kate", "Firefox", "Google Chrome", "Chromium", "Discord", "Spotify", "VLC"]
    function isUtility(e) {
        if (keepOut.some(k => e.name.startsWith(k))) return false;
        const c = e.categories || [];
        return c.includes("System") || c.includes("Utility") || c.includes("Settings") || c.includes("Monitor");
    }
    readonly property var tiles: {
        if (search.text.trim()) return apps;
        const main = apps.filter(e => !isUtility(e));
        const utils = apps.filter(e => isUtility(e));
        return utils.length > 1 ? main.concat([{ folder: true, name: qsTr("Utilities"), apps: utils }]) : apps;
    }
    property var openFolder: null
    function openUtilities() { if (!visible) toggle(); openFolder = tiles.find(t => t.folder) || null; }

    // blurred, dimmed wallpaper
    Item {
        anchors.fill: parent
        opacity: pad.shown
        Image {
            id: bg
            anchors.fill: parent
            source: R.Theme.wallpaper
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(pad.width / 2, pad.height / 2)
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: bg
            blurEnabled: true; blur: 1.0; blurMax: 64
            saturation: 0.2
        }
        Rectangle { anchors.fill: parent; color: R.Theme.dark ? Qt.rgba(0, 0, 0, 0.45) : Qt.rgba(1, 1, 1, 0.35) }
        MouseArea { anchors.fill: parent; onClicked: pad.hide() }
    }

    Item {
        anchors.fill: parent
        // Ravana zoom: apps settle in from slightly larger, like stepping back to see them all
        opacity: pad.shown
        scale: 1.07 - 0.07 * pad.shown
        Keys.onEscapePressed: pad.openFolder ? pad.openFolder = null : pad.hide()

        // search pill
        Rectangle {
            id: pill
            anchors.horizontalCenter: parent.horizontalCenter
            y: 70
            width: 320; height: 36; radius: 18
            color: R.Theme.dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.07)
            border.width: 1
            border.color: R.Theme.dark ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.08)
            Kirigami.Icon {
                x: 12; anchors.verticalCenter: parent.verticalCenter
                width: 16; height: 16; source: "search-symbolic"; isMask: true; color: pad.ink; opacity: 0.7
            }
            TextInput {
                id: search
                anchors.fill: parent
                anchors.leftMargin: 36; anchors.rightMargin: 14
                verticalAlignment: TextInput.AlignVCenter
                color: pad.ink
                font.family: R.Theme.fontFamily
                font.pixelSize: 15
                selectByMouse: true
                onTextChanged: pages.currentIndex = 0
                Keys.onLeftPressed: e => { if (!search.text) pages.decrementCurrentIndex(); else e.accepted = false; }
                Keys.onRightPressed: e => { if (!search.text) pages.incrementCurrentIndex(); else e.accepted = false; }
                Keys.onEscapePressed: search.text ? search.text = "" : (pad.openFolder ? pad.openFolder = null : pad.hide())
                Keys.onReturnPressed: if (pad.apps.length) { pad.launch(pad.apps[0]); pad.hide(); }
                Text {
                    textFormat: Text.PlainText
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Search")
                    color: pad.ink; opacity: 0.5
                    font: search.font
                    visible: !search.text && !search.activeFocus
                }
            }
        }

        // Pages of apps: swipe / scroll / ← → between them, dots below
        Item {
            id: area
            anchors.top: pill.bottom
            anchors.topMargin: 44
            anchors.bottom: dots.top
            anchors.bottomMargin: 18
            anchors.left: parent.left
            anchors.right: parent.right
            readonly property int columns: Math.max(4, Math.min(7, Math.floor((pad.width - 160) / 150)))
            readonly property int rows: Math.max(2, Math.min(5, Math.floor(height / 140)))
            readonly property int perPage: columns * rows
            readonly property int pageCount: Math.max(1, Math.ceil(pad.tiles.length / perPage))
        }
        ListView {
            id: pages
            anchors.fill: area
            orientation: ListView.Horizontal
            snapMode: ListView.SnapOneItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveDuration: R.Theme.normal * 2
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            model: pad.visible ? area.pageCount : 0
            Keys.onLeftPressed: decrementCurrentIndex()
            Keys.onRightPressed: incrementCurrentIndex()
            WheelHandler {
                property real acc: 0
                onWheel: e => {
                    acc += (Math.abs(e.angleDelta.x) > Math.abs(e.angleDelta.y) ? -e.angleDelta.x : -e.angleDelta.y);
                    if (acc > 120) { pages.incrementCurrentIndex(); acc = 0; }
                    else if (acc < -120) { pages.decrementCurrentIndex(); acc = 0; }
                }
            }
            delegate: Item {
                id: page
                required property int index
                width: pages.width; height: pages.height
                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: area.columns
                    Repeater {
                        model: pad.tiles.slice(page.index * area.perPage, (page.index + 1) * area.perPage)
                        delegate: MouseArea {
                            id: cellMouse
                            required property var modelData
                            width: 150; height: 140
                            hoverEnabled: true
                            onClicked: modelData.folder ? pad.openFolder = modelData : (pad.launch(modelData), pad.hide())
                            Rectangle {
                                anchors.fill: parent; anchors.margins: 6
                                radius: R.Theme.radiusLarge
                                color: R.Theme.dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)
                                opacity: cellMouse.containsMouse ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: R.Theme.fast } }
                            }
                            R.AppIcon {
                                visible: !cellMouse.modelData.folder
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 14
                                size: 84
                                source: cellMouse.modelData.folder ? "" : cellMouse.modelData.icon
                                scale: cellMouse.pressed ? 0.92 : 1
                                Behavior on scale { NumberAnimation { duration: 90 } }
                            }
                            Rectangle {       // folder: frosted squircle with a 3×3 preview
                                visible: !!cellMouse.modelData.folder
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 18
                                width: 76; height: 76; radius: 18
                                color: R.Theme.dark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.55)
                                border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.22)
                                scale: cellMouse.pressed ? 0.92 : 1
                                Grid {
                                    anchors.centerIn: parent
                                    columns: 3; spacing: 4
                                    Repeater {
                                        model: cellMouse.modelData.folder ? cellMouse.modelData.apps.slice(0, 9) : []
                                        Kirigami.Icon { required property var modelData; width: 18; height: 18; source: modelData.icon }
                                    }
                                }
                            }
                            Text {
                                textFormat: Text.PlainText
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 106
                                width: 136
                                horizontalAlignment: Text.AlignHCenter
                                text: cellMouse.modelData.name
                                elide: Text.ElideRight
                                color: pad.ink
                                style: R.Theme.dark ? Text.Raised : Text.Normal
                                styleColor: Qt.rgba(0, 0, 0, 0.35)
                                font.family: R.Theme.fontFamily
                                font.pixelSize: 13
                                renderType: Text.NativeRendering
                            }
                        }
                    }
                }
            }
        }

        // open folder: frosted panel over a dimmed Launchpad, click outside to close
        Item {
            id: folderView
            anchors.fill: parent
            visible: opacity > 0
            opacity: pad.openFolder ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: R.Theme.normal; easing.type: Easing.OutCubic } }
            MouseArea { anchors.fill: parent; onClicked: pad.openFolder = null }
            Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, R.Theme.dark ? 0.45 : 0.2) }   // dim the page behind
            Rectangle {
                id: folderPanel
                readonly property var list: pad.openFolder ? pad.openFolder.apps : []
                readonly property int cols: Math.min(5, Math.max(3, list.length))
                width: cols * 130 + 60
                height: Math.ceil(list.length / cols) * 130 + 110
                anchors.centerIn: parent
                radius: 34
                color: R.Theme.dark ? Qt.rgba(0.16, 0.15, 0.17, 0.88) : Qt.rgba(0.97, 0.97, 0.98, 0.9)
                border.width: 1; border.color: R.Theme.glassRim
                scale: pad.openFolder ? 1 : 0.85
                Behavior on scale { NumberAnimation { duration: R.Theme.bloom; easing.type: Easing.OutBack; easing.overshoot: R.Theme.bloomOvershoot } }
                MouseArea { anchors.fill: parent }
                Text {
                    textFormat: Text.PlainText
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 22
                    text: pad.openFolder ? pad.openFolder.name : ""
                    color: R.Theme.text
                    font.family: R.Theme.fontFamily; font.pixelSize: 22; font.weight: Font.DemiBold
                }
                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 72
                    columns: folderPanel.cols
                    Repeater {
                        model: folderPanel.list
                        MouseArea {
                            id: fcell
                            required property var modelData
                            width: 130; height: 130
                            hoverEnabled: true
                            onClicked: { pad.launch(modelData); pad.openFolder = null; pad.hide(); }
                            R.AppIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 10; size: 72
                                source: fcell.modelData.icon
                                scale: fcell.pressed ? 0.92 : 1
                            }
                            Text {
                                textFormat: Text.PlainText
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 92; width: 120
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                text: fcell.modelData.name
                                color: R.Theme.text
                                font.family: R.Theme.fontFamily; font.pixelSize: 12
                            }
                        }
                    }
                }
            }
        }

        Row {
            id: dots
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 46
            spacing: 10
            visible: area.pageCount > 1
            Repeater {
                model: area.pageCount
                Rectangle {
                    required property int index
                    width: 8; height: 8; radius: 4
                    color: pad.ink
                    opacity: index === pages.currentIndex ? 0.95 : 0.35
                    Behavior on opacity { NumberAnimation { duration: R.Theme.fast } }
                    MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: pages.currentIndex = parent.index }
                }
            }
        }
    }
}
