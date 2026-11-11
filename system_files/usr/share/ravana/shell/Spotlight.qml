// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana Spotlight: a glass capsule in the upper third. Results grouped as
// Top Hit, Applications, Calculator, Files and Web. ↑ ↓ to move, ⏎ to open, Esc to close.
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import org.kde.kirigami as Kirigami
import org.ravana.ui as R

PanelWindow {
    id: spot
    visible: false
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ravana-spotlight"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    property real shown: 0
    Behavior on shown { NumberAnimation { duration: R.Theme.fast; easing.type: Easing.OutCubic } }
    function toggle() { if (visible) hide(); else open(""); }
    function open(text) {
        field.text = text; selected = 0; files = [];
        visible = true; shown = 1; bloomIn.restart(); field.forceActiveFocus();
    }
    function hide() { shown = 0; closeTimer.restart(); }
    // Open an app; one that needs a terminal (htop, …) opens inside one
    function launch(e) {
        if (e.runInTerminal && e.command && e.command.length)
            Quickshell.execDetached(["sh", "-c", 'if command -v konsole >/dev/null; then exec konsole -e "$@"; else exec ptyxis -- "$@"; fi', "sh"].concat(Array.from(e.command)));
        else e.execute();
    }
    property real reveal: 0
    NumberAnimation { id: bloomIn; target: spot; property: "reveal"; from: 0; to: 1
        duration: R.Theme.bloom; easing.type: Easing.OutBack; easing.overshoot: R.Theme.bloomOvershoot }
    Timer { id: closeTimer; interval: R.Theme.fast; onTriggered: spot.visible = false }

    readonly property string query: field.text.trim()

    // ---- sources ----
    readonly property var apps: {
        const q = query.toLowerCase();
        if (!q) return [];
        const score = e => {
            const n = e.name.toLowerCase();
            return n.startsWith(q) ? 0 : n.split(/\s+/).some(w => w.startsWith(q)) ? 1
                 : n.includes(q) ? 2 : 3;
        };
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay && e.name && !R.Theme.hiddenApps.some(h => e.name.startsWith(h)))
            .filter(e => (e.name.toLowerCase().includes(q)
                     || (e.genericName || "").toLowerCase().includes(q)
                     || (e.keywords || []).some(k => k.toLowerCase().includes(q))))
            .sort((a, b) => score(a) - score(b) || a.name.localeCompare(b.name))
            .slice(0, 7);
    }
    readonly property string calc: {
        if (!/^[\d\s+\-*/().,%^]+$/.test(query) || !/\d/.test(query) || !/[+\-*/%^]/.test(query)) return "";
        try {
            const v = Function('"use strict"; return (' + query.replace(/,/g, ".").replace(/\^/g, "**") + ")")();
            return (typeof v === "number" && isFinite(v)) ? String(Math.round(v * 1e10) / 1e10) : "";
        } catch (e) { return ""; }
    }
    // Settings pages (Ravana Settings), found by name and common words
    readonly property var settingsPages: [
        ["wifi", qsTr("Wi-Fi"), "network-wireless-symbolic", "wireless internet network"],
        ["bluetooth", qsTr("Bluetooth"), "network-bluetooth-symbolic", "headphones pair devices"],
        ["sound", qsTr("Sound"), "audio-volume-high-symbolic", "volume speakers output"],
        ["displays", qsTr("Displays"), "video-display-symbolic", "screen brightness resolution monitor"],
        ["appearance", qsTr("Appearance"), "preferences-desktop-theme-global-symbolic", "dark light mode theme"],
        ["desktop", qsTr("Desktop & Dock"), "preferences-desktop-symbolic", "dock size magnification hide shortcuts"],
        ["focus", qsTr("Focus"), "notifications-disabled-symbolic", "do not disturb"],
        ["notifications", qsTr("Notifications"), "notifications-symbolic", "alerts banners"],
        ["trackpad", qsTr("Trackpad"), "input-touchpad-symbolic", "gestures touchpad"],
        ["keyboard", qsTr("Keyboard"), "input-keyboard-symbolic", "layout language typing"],
        ["update", qsTr("Software Update"), "update-none", "upgrade new version"],
        ["about", qsTr("About This Computer"), "help-about-symbolic", "version specs system"],
        ["battery", qsTr("Battery & Power"), "battery-good-symbolic", "sleep energy"],
        ["users", qsTr("Users & Groups"), "system-users-symbolic", "account password"]
    ]
    readonly property var settingsHits: {
        const q = query.toLowerCase();
        if (q.length < 2) return [];
        // a page matches when its name or one of its words starts with what you typed
        const starts = t => t.toLowerCase().split(/[^a-z0-9]+/).some(w => w.startsWith(q));
        return settingsPages.filter(p => starts(p[1]) || starts(p[3])).slice(0, 3);
    }
    property var files: []
    Process {
        id: finder
        stdout: StdioCollector {
            onStreamFinished: spot.files = text.split("\n").filter(l => l.startsWith("/")).slice(0, 5)
        }
    }
    Timer {
        id: fileDelay; interval: 220
        onTriggered: {
            if (spot.query.length < 3) { spot.files = []; return; }
            finder.running = false;
            finder.command = ["sh", "-c", 'command -v baloosearch6 >/dev/null && baloosearch6 -l 5 -- "$1" 2>/dev/null', "sh", spot.query];
            finder.running = true;
        }
    }
    onQueryChanged: { selected = 0; fileDelay.restart(); }

    // One flat list for the keyboard, grouped for display
    readonly property var results: {
        const r = [];
        apps.forEach((a, i) => r.push({ group: i === 0 ? qsTr("Top Hit") : qsTr("Applications"),
                                        top: i === 0, title: a.name, sub: a.genericName || "", icon: a.icon, app: a }));
        if (calc) r.splice(apps.length ? 1 : 0, 0, { group: qsTr("Calculator"), title: calc, sub: query + " =", icon: "accessories-calculator", copy: calc });
        settingsHits.forEach(p => r.push({ group: qsTr("System Settings"), title: p[1], sub: "", icon: p[2], page: p[0] }));
        files.forEach(f => r.push({ group: qsTr("Files"), title: f.split("/").pop(), sub: f.replace(Quickshell.env("HOME"), "~"), icon: "document-open", path: f }));
        if (query) r.push({ group: qsTr("Web"), title: qsTr("Search the web for “%1”").arg(query), sub: "", icon: "internet-web-browser", web: query });
        return r;
    }
    property int selected: 0

    function activate(r) {
        if (!r) return;
        if (r.app) spot.launch(r.app);
        else if (r.copy) runner.exec(["wl-copy", r.copy]);
        else if (r.path) runner.exec(["xdg-open", r.path]);
        else if (r.page) runner.exec(["ravana-settings", r.page]);
        else if (r.web) runner.exec(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(r.web)]);
        hide();
    }
    // Detached: Spotlight is unloaded after it hides, which would kill a Process it owns
    QtObject { id: runner; function exec(c) { Quickshell.execDetached(c); } }

    MouseArea { anchors.fill: parent; onClicked: spot.hide() }

    Item {
        id: box
        width: Math.min(680, spot.width - 48)
        height: col.implicitHeight
        Behavior on height { NumberAnimation { duration: R.Theme.fast; easing.type: Easing.OutCubic } }
        anchors.horizontalCenter: parent.horizontalCenter
        y: spot.height * 0.22
        opacity: spot.shown
        scale: spot.shown < 1 && !bloomIn.running ? 0.97 + 0.03 * spot.shown : R.Theme.bloomFrom + (1 - R.Theme.bloomFrom) * spot.reveal
        transformOrigin: Item.Top

        RectangularShadow {
            anchors.fill: glass; radius: glass.radius
            blur: 40; offset: Qt.vector2d(0, 14); color: R.Theme.shadow
        }
        Rectangle {
            id: glass
            anchors.fill: parent
            radius: spot.results.length ? 22 : height / 2
            color: R.Theme.glassTint("thick")
            border.width: 1; border.color: R.Theme.glassRim
            Behavior on radius { NumberAnimation { duration: R.Theme.fast } }
            MouseArea { anchors.fill: parent }     // clicks inside don't close
        }

        ColumnLayout {
            id: col
            anchors.left: parent.left; anchors.right: parent.right
            spacing: 0

            Item {   // the capsule
                Layout.fillWidth: true
                implicitHeight: 56
                Kirigami.Icon {
                    x: 20; anchors.verticalCenter: parent.verticalCenter
                    width: 22; height: 22; source: "search-symbolic"; isMask: true
                    color: R.Theme.secondaryText
                }
                TextInput {
                    id: field
                    anchors.fill: parent
                    anchors.leftMargin: 54; anchors.rightMargin: 20
                    verticalAlignment: TextInput.AlignVCenter
                    color: R.Theme.text
                    font.family: R.Theme.fontFamily; font.pixelSize: 22
                    selectByMouse: true
                    Keys.onEscapePressed: field.text ? field.text = "" : spot.hide()
                    Keys.onDownPressed: spot.selected = Math.min(spot.selected + 1, spot.results.length - 1)
                    Keys.onUpPressed: spot.selected = Math.max(spot.selected - 1, 0)
                    Keys.onReturnPressed: spot.activate(spot.results[spot.selected])
                    Text {
                        textFormat: Text.PlainText
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Ravana Search")
                        color: R.Theme.tertiaryText
                        font: field.font
                        visible: !field.text
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 1
                visible: spot.results.length > 0
                color: R.Theme.blockBorder
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 8
                visible: spot.results.length > 0
                spacing: 0
                Repeater {
                    model: spot.results
                    ColumnLayout {
                        id: entry
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        spacing: 0
                        Text { textFormat: Text.PlainText;   // group header, once per group
                            visible: entry.index === 0 || spot.results[entry.index - 1].group !== entry.modelData.group
                            Layout.leftMargin: 12; Layout.topMargin: entry.index === 0 ? 4 : 10; Layout.bottomMargin: 4
                            text: entry.modelData.group
                            color: R.Theme.secondaryText
                            font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeCaption; font.weight: Font.DemiBold
                        }
                        MouseArea {
                            id: rowArea
                            Layout.fillWidth: true
                            implicitHeight: entry.modelData.top ? 58 : 38
                            hoverEnabled: true
                            onEntered: spot.selected = entry.index
                            onClicked: spot.activate(entry.modelData)
                            readonly property bool sel: spot.selected === entry.index
                            Rectangle {
                                anchors.fill: parent
                                radius: R.Theme.radiusHighlight + 3
                                color: R.Theme.accent
                                opacity: rowArea.sel ? 1 : 0
                            }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10; anchors.rightMargin: 12
                                spacing: 10
                                R.AppIcon {
                                    size: entry.modelData.top ? 40 : 24
                                    source: entry.modelData.icon
                                }
                                Text {
                                    textFormat: Text.PlainText
                                    Layout.fillWidth: true
                                    text: entry.modelData.title
                                    elide: Text.ElideRight
                                    color: rowArea.sel ? R.Theme.textOnAccent : R.Theme.text
                                    font.family: R.Theme.fontFamily
                                    font.pixelSize: entry.modelData.top ? 17 : R.Theme.sizeBody
                                    font.weight: entry.modelData.top ? Font.DemiBold : Font.Normal
                                }
                                Text {
                                    textFormat: Text.PlainText
                                    Layout.maximumWidth: box.width * 0.45
                                    text: entry.modelData.sub
                                    elide: Text.ElideMiddle
                                    color: rowArea.sel ? Qt.rgba(1, 1, 1, 0.8) : R.Theme.tertiaryText
                                    font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeCaption
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
