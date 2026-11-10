// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana Settings: floating inset sidebar with search, coloured squircle icons, and
// pages of inset grouped rows. The everyday settings work right here; "Advanced…"
// opens the matching KDE page for the rest.
//   open:  qs ipc -p /usr/share/ravana/settings call settings open <page>
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import org.kde.kirigami as Kirigami
import org.ravana.ui as R

ShellRoot {
    id: app

    property string page: Quickshell.env("RAVANA_SETTINGS_PAGE") || "appearance"
    property var st: ({})
    property var about: ({})
    function flag(k) { return st[k] === "1"; }
    function kv(text) {
        const s = {};
        text.split("\n").forEach(l => { const i = l.indexOf("="); if (i > 0) s[l.slice(0, i)] = l.slice(i + 1); });
        return s;
    }

    Process { id: status; command: ["/usr/libexec/ravana-cc", "status"]
        stdout: StdioCollector { onStreamFinished: app.st = app.kv(text) } }
    Process { id: aboutReader; running: true; command: ["/usr/libexec/ravana-about"]
        stdout: StdioCollector { onStreamFinished: app.about = app.kv(text) } }
    Timer { interval: 3000; repeat: true; running: win.visible; triggeredOnStart: true; onTriggered: status.running = true }

    Process { id: runner }
    function run(args) { runner.command = args; runner.running = true; refresh.restart(); }
    function cc(args) { run(["/usr/libexec/ravana-cc"].concat(args)); }
    function kcm(name) { run(["systemsettings", name]); }
    Timer { id: refresh; interval: 700; onTriggered: status.running = true }

    // Wi-Fi networks / Bluetooth devices
    property var rows: []
    Process { id: lister
        stdout: StdioCollector { onStreamFinished: app.rows = text.split("\n").filter(l => l.length).map(l => l.split("\t")) } }
    function list(kind) { rows = []; lister.command = ["/usr/libexec/ravana-cc", kind]; lister.running = true; }
    onPageChanged: if (page === "wifi") list("wifi-list"); else if (page === "bluetooth") list("bt-list")

    readonly property var sections: [
        { id: "about", name: qsTr("About"), icon: "help-about-symbolic", tint: "#8e8e93", group: 0 },
        { id: "update", name: qsTr("Software Update"), icon: "update-none", tint: "#8e8e93", group: 0 },
        { id: "wifi", name: qsTr("Wi-Fi"), icon: "network-wireless-symbolic", tint: "#0a84ff", group: 1 },
        { id: "bluetooth", name: qsTr("Bluetooth"), icon: "network-bluetooth-symbolic", tint: "#0a84ff", group: 1 },
        { id: "network", name: qsTr("Network"), icon: "network-wired-symbolic", tint: "#0a84ff", group: 1 },
        { id: "notifications", name: qsTr("Notifications"), icon: "notifications-symbolic", tint: "#d21f3c", group: 2 },
        { id: "sound", name: qsTr("Sound"), icon: "audio-volume-high-symbolic", tint: "#d21f3c", group: 2 },
        { id: "focus", name: qsTr("Focus"), icon: "notifications-disabled-symbolic", tint: "#5e5ce6", group: 2 },
        { id: "appearance", name: qsTr("Appearance"), icon: "preferences-desktop-theme-global-symbolic", tint: "#1d1d1f", group: 3 },
        { id: "desktop", name: qsTr("Desktop & Dock"), icon: "preferences-desktop-symbolic", tint: "#1d1d1f", group: 3 },
        { id: "displays", name: qsTr("Displays"), icon: "video-display-symbolic", tint: "#0a84ff", group: 3 },
        { id: "battery", name: qsTr("Battery & Power"), icon: "battery-good-symbolic", tint: "#30d158", group: 3 },
        { id: "lock", name: qsTr("Lock Screen"), icon: "system-lock-screen-symbolic", tint: "#1d1d1f", group: 4 },
        { id: "privacy", name: qsTr("Privacy & Security"), icon: "security-high-symbolic", tint: "#0a84ff", group: 4 },
        { id: "users", name: qsTr("Users & Groups"), icon: "system-users-symbolic", tint: "#0a84ff", group: 4 },
        { id: "keyboard", name: qsTr("Keyboard"), icon: "input-keyboard-symbolic", tint: "#8e8e93", group: 5 },
        { id: "trackpad", name: qsTr("Trackpad"), icon: "input-touchpad-symbolic", tint: "#8e8e93", group: 5 },
        { id: "mouse", name: qsTr("Mouse"), icon: "input-mouse-symbolic", tint: "#8e8e93", group: 5 },
        { id: "gaming", name: qsTr("Game Mode"), icon: "input-gaming-symbolic", tint: "#d21f3c", group: 5 }
    ]
    readonly property var shown: {
        const q = search.text.trim().toLowerCase();
        return q ? sections.filter(s => s.name.toLowerCase().includes(q)) : sections;
    }
    readonly property var current: sections.find(s => s.id === page) || sections[0]

    IpcHandler {
        target: "settings"
        function open(name: string): void { if (name) app.page = name; win.visible = true; }
    }

    FloatingWindow {
        id: win
        title: qsTr("Ravana Settings")
        implicitWidth: 860
        implicitHeight: 680
        color: R.Theme.dark ? "#1c1b1e" : "#f2f1f4"
        onVisibleChanged: if (!visible) Qt.quit()

        // ---- sidebar: floating, inset glass ----
        Rectangle {
            id: sidebar
            x: 8; y: 8
            width: 230; height: parent.height - 16
            radius: 14
            color: R.Theme.dark ? Qt.rgba(1, 1, 1, 0.045) : Qt.rgba(1, 1, 1, 0.7)
            border.width: 1
            border.color: R.Theme.dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.06)

            Rectangle {      // search capsule
                id: searchBox
                x: 10; y: 12; width: parent.width - 20; height: 30; radius: 9
                color: R.Theme.dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)
                Kirigami.Icon { x: 8; anchors.verticalCenter: parent.verticalCenter; width: 14; height: 14
                    source: "search-symbolic"; isMask: true; color: R.Theme.secondaryText }
                TextInput {
                    id: search
                    anchors.fill: parent; anchors.leftMargin: 28; anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: R.Theme.text
                    font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody
                    Text { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Search"); visible: !search.text
                        color: R.Theme.tertiaryText; font: search.font }
                    Keys.onReturnPressed: if (app.shown.length) app.page = app.shown[0].id
                }
            }
            ListView {
                id: nav
                anchors.top: searchBox.bottom; anchors.topMargin: 10
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                anchors.margins: 8
                clip: true
                model: app.shown
                spacing: 1
                delegate: Item {
                    id: navItem
                    required property var modelData
                    required property int index
                    readonly property bool gap: index > 0 && app.shown[index - 1].group !== modelData.group
                    width: nav.width; height: 28 + (gap ? 8 : 0)
                    MouseArea {
                        id: navArea
                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                        height: 28
                        hoverEnabled: true
                        onClicked: app.page = navItem.modelData.id
                        Rectangle {
                            anchors.fill: parent; radius: 7
                            color: app.page === navItem.modelData.id ? R.Theme.accent : R.Theme.hover
                            visible: app.page === navItem.modelData.id || navArea.containsMouse
                        }
                        Rectangle {    // coloured squircle
                            id: sq
                            x: 6; anchors.verticalCenter: parent.verticalCenter
                            width: 22; height: 22; radius: 6
                            color: navItem.modelData.tint === "#1d1d1f" && R.Theme.dark ? "#48484a" : navItem.modelData.tint
                            Kirigami.Icon { anchors.centerIn: parent; width: 14; height: 14
                                source: navItem.modelData.icon; isMask: true; color: "white" }
                        }
                        Text {
                            anchors.left: sq.right; anchors.leftMargin: 9; anchors.verticalCenter: parent.verticalCenter
                            text: navItem.modelData.name
                            color: app.page === navItem.modelData.id ? R.Theme.textOnAccent : R.Theme.text
                            font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody
                        }
                    }
                }
            }
        }

        // ---- page ----
        Flickable {
            id: pageArea
            anchors.left: sidebar.right; anchors.right: parent.right
            anchors.top: parent.top; anchors.bottom: parent.bottom
            anchors.leftMargin: 8
            contentHeight: pageCol.implicitHeight + 40
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ColumnLayout {
                id: pageCol
                x: 24; y: 18
                width: pageArea.width - 48
                spacing: 18
                Text {
                    text: app.current.name
                    color: R.Theme.text
                    font.family: R.Theme.fontFamily; font.pixelSize: 20; font.weight: Font.Bold
                }
                Loader {
                    id: pageLoader
                    Layout.fillWidth: true
                    sourceComponent: ({
                        about: aboutPage, update: updatePage, wifi: wifiPage, bluetooth: btPage,
                        sound: soundPage, focus: focusPage, appearance: appearancePage,
                        displays: displaysPage, trackpad: trackpadPage, desktop: desktopPage
                    })[app.page] || linkPage
                    // pages glide in
                    onLoaded: { item.opacity = 0; fadeIn.restart(); }
                    NumberAnimation { id: fadeIn; target: pageLoader.item; property: "opacity"; to: 1; duration: R.Theme.normal; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    // ================= pages =================
    Component {
        id: aboutPage
        ColumnLayout {
            spacing: 18
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4
                Image {
                    Layout.alignment: Qt.AlignHCenter
                    source: "file:///usr/share/icons/hicolor/256x256/apps/ravana-logo.png"
                    sourceSize: Qt.size(120, 120)
                }
                Text { Layout.alignment: Qt.AlignHCenter; text: app.about.name || "Ravana OS"; color: R.Theme.text
                    font.family: R.Theme.fontFamily; font.pixelSize: 26; font.weight: Font.Bold }
                Text { Layout.alignment: Qt.AlignHCenter; text: (app.about.version ? qsTr("Version %1").arg(app.about.version) : "") + (app.about.base ? "  ·  " + app.about.base : ""); color: R.Theme.secondaryText
                    font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody }
            }
            R.SettingsGroup {
                R.SettingsRow { label: qsTr("Name"); detail: app.about.host || "—" }
                R.SettingsRow { label: qsTr("Chip"); detail: app.about.chip || "—" }
                R.SettingsRow { label: qsTr("Cores"); detail: app.about.cores || "—" }
                R.SettingsRow { label: qsTr("Memory"); detail: app.about.memory || "—" }
                R.SettingsRow { label: qsTr("Graphics"); detail: app.about.graphics || "—" }
                R.SettingsRow { label: qsTr("Storage"); detail: app.about.disk || "—" }
                R.SettingsRow { label: qsTr("Kernel"); detail: app.about.kernel || "—"; last: true }
            }
            R.SettingsGroup {
                R.SettingsRow { label: qsTr("System Report…"); chevron: true; last: true; onClicked: app.run(["kinfocenter"]) }
            }
        }
    }
    Component {
        id: updatePage
        ColumnLayout {
            spacing: 18
            R.SettingsGroup {
                footer: qsTr("Ravana updates arrive as a whole, tested system image. Your files and apps are never touched, and the previous version stays available at startup.")
                R.SettingsRow { label: qsTr("Version"); detail: app.about.image || app.about.version || "—" }
                R.SettingsRow { label: qsTr("Update channel"); detail: app.about.channel || "—"; last: true }
            }
            RowLayout {
                Item { Layout.fillWidth: true }
                R.PushButton { text: qsTr("Check for Updates…"); primary: true; onClicked: app.run(["gtk-launch", "ravana-update"]) }
            }
        }
    }
    Component {
        id: wifiPage
        ColumnLayout {
            spacing: 18
            R.SettingsGroup {
                R.SettingsRow { label: qsTr("Wi-Fi"); icon: "network-wireless-symbolic"; last: true
                    R.ToggleSwitch { on: app.flag("wifi_on"); onToggled: app.cc(["wifi", on ? "off" : "on"]) } }
            }
            R.SettingsGroup {
                title: qsTr("Known and nearby networks")
                R.SettingsRow { visible: app.rows.length === 0; label: lister.running ? qsTr("Searching…") : qsTr("No networks found"); last: true }
                Repeater {
                    model: app.rows
                    R.SettingsRow {
                        required property var modelData
                        required property int index
                        label: modelData[1]
                        detail: modelData[0] === "*" ? qsTr("Connected") : ((modelData[3] || "--") !== "--" ? "🔒" : "")
                        chevron: modelData[0] !== "*"
                        last: index === app.rows.length - 1
                        onClicked: ((modelData[3] || "--") !== "--" && modelData[4] !== "1")
                            ? app.run(["qs", "ipc", "-p", "/usr/share/ravana/shell", "call", "controlcenter", "join", modelData[1]])
                            : app.cc(["wifi-connect", modelData[1]])
                    }
                }
            }
            RowLayout { Item { Layout.fillWidth: true } R.PushButton { text: qsTr("Advanced…"); onClicked: app.kcm("kcm_networkmanagement") } }
        }
    }
    Component {
        id: btPage
        ColumnLayout {
            spacing: 18
            R.SettingsGroup {
                R.SettingsRow { label: qsTr("Bluetooth"); icon: "network-bluetooth-symbolic"; last: true
                    R.ToggleSwitch { on: app.flag("bt_on"); onToggled: app.cc(["bluetooth", on ? "off" : "on"]) } }
            }
            R.SettingsGroup {
                title: qsTr("My Devices")
                R.SettingsRow { visible: app.rows.length === 0; label: qsTr("No paired devices"); last: true }
                Repeater {
                    model: app.rows
                    R.SettingsRow {
                        required property var modelData
                        required property int index
                        label: modelData[1]
                        detail: modelData[2] === "1" ? qsTr("Connected") : qsTr("Not Connected")
                        chevron: true
                        last: index === app.rows.length - 1
                        onClicked: app.cc(["bt-device", modelData[0]])
                    }
                }
            }
            RowLayout { Item { Layout.fillWidth: true } R.PushButton { text: qsTr("Pair a New Device…"); onClicked: app.kcm("kcm_bluetooth") } }
        }
    }
    Component {
        id: soundPage
        ColumnLayout {
            spacing: 18
            R.SettingsGroup {
                title: qsTr("Output volume")
                R.SettingsRow { label: ""; last: true
                    R.PillSlider { implicitWidth: pageCol.width - 40; iconName: "audio-volume-high-symbolic"
                        value: parseInt(app.st.volume || "50") / 100
                        onReleased: v => app.cc(["volume", String(Math.round(v * 100))]) } }
            }
            R.SettingsGroup {
                R.SettingsRow { label: qsTr("Mute"); last: true
                    R.ToggleSwitch { on: app.flag("muted"); onToggled: app.cc(["mute", "toggle"]) } }
            }
            RowLayout { Item { Layout.fillWidth: true } R.PushButton { text: qsTr("Devices and Advanced…"); onClicked: app.kcm("kcm_pulseaudio") } }
        }
    }
    Component {
        id: focusPage
        ColumnLayout {
            spacing: 18
            R.SettingsGroup {
                footer: qsTr("Focus silences notifications until you turn it off. Critical alerts still come through.")
                R.SettingsRow { label: qsTr("Do Not Disturb"); icon: "notifications-disabled-symbolic"; last: true
                    R.ToggleSwitch { on: app.flag("focus_on"); onToggled: app.cc(["focus", on ? "off" : "on"]) } }
            }
            RowLayout { Item { Layout.fillWidth: true } R.PushButton { text: qsTr("Notification Settings…"); onClicked: app.kcm("kcm_notifications") } }
        }
    }
    Component {
        id: appearancePage
        ColumnLayout {
            spacing: 18
            R.SettingsGroup {
                title: qsTr("Appearance")
                footer: qsTr("Ravana's look is the same everywhere: menus, apps, browsers and games' launchers follow it.")
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 150
                    Row {
                        anchors.centerIn: parent
                        spacing: 28
                        Repeater {
                            model: [ { id: "light", name: qsTr("Light") }, { id: "dark", name: qsTr("Dark") } ]
                            Column {
                                id: mode
                                required property var modelData
                                readonly property bool active: (modelData.id === "dark") === R.Theme.dark
                                spacing: 8
                                Rectangle {
                                    width: 120; height: 78; radius: 10
                                    border.width: mode.active ? 3 : 1
                                    border.color: mode.active ? R.Theme.accent : R.Theme.blockBorder
                                    clip: true
                                    Image {
                                        anchors.fill: parent; anchors.margins: mode.active ? 3 : 1
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize: Qt.size(240, 156)
                                        source: mode.modelData.id === "dark"
                                            ? "file:///usr/share/wallpapers/RavanaLanka/contents/screenshot.png"
                                            : "file:///usr/share/wallpapers/Ravana/contents/screenshot_light.png"
                                    }
                                    MouseArea { anchors.fill: parent; onClicked: app.run(["/usr/libexec/ravana-appearance", mode.modelData.id]) }
                                }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: mode.modelData.name
                                    color: R.Theme.text; font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody
                                    font.weight: mode.active ? Font.DemiBold : Font.Normal }
                            }
                        }
                    }
                }
            }
            R.SettingsGroup {
                R.SettingsRow { label: qsTr("Accent colour"); detail: qsTr("Ravana Red")
                    Rectangle { width: 16; height: 16; radius: 8; color: R.Theme.accent } }
                R.SettingsRow { label: qsTr("Window buttons"); detail: qsTr("Red · Yellow · Green, on the left"); last: true }
            }
        }
    }
    Component {
        id: displaysPage
        ColumnLayout {
            spacing: 18
            R.SettingsGroup {
                title: qsTr("Brightness")
                R.SettingsRow { visible: !app.flag("brightness_available"); label: qsTr("This display's brightness is set on the display itself."); last: true }
                R.SettingsRow { visible: app.flag("brightness_available"); label: ""; last: true
                    R.PillSlider { implicitWidth: pageCol.width - 40; iconName: "brightness-high-symbolic"
                        value: parseInt(app.st.brightness || "50") / 100
                        onReleased: v => app.cc(["brightness", String(Math.round(v * 100))]) } }
            }
            R.SettingsGroup {
                R.SettingsRow { label: qsTr("Resolution, scale and arrangement"); chevron: true; onClicked: app.kcm("kcm_kscreen") }
                R.SettingsRow { label: qsTr("Night Shift"); chevron: true; last: true; onClicked: app.kcm("kcm_nightlight") }
            }
        }
    }
    Component {
        id: trackpadPage
        ColumnLayout {
            spacing: 18
            R.SettingsGroup {
                title: qsTr("Gestures")
                R.SettingsRow { label: qsTr("Mission Control"); detail: qsTr("Swipe up with three fingers") }
                R.SettingsRow { label: qsTr("App Exposé"); detail: qsTr("Swipe down with three fingers") }
                R.SettingsRow { label: qsTr("Switch between Spaces"); detail: qsTr("Swipe left or right with three fingers") }
                R.SettingsRow { label: qsTr("Launchpad"); detail: qsTr("Swipe up with four fingers, or pinch") }
                R.SettingsRow { label: qsTr("Show Desktop"); detail: qsTr("Spread with four fingers") }
                R.SettingsRow { label: qsTr("Notification Center"); detail: qsTr("Swipe left with four fingers"); last: true }
            }
            RowLayout { Item { Layout.fillWidth: true } R.PushButton { text: qsTr("Tracking, Tap and Scrolling…"); onClicked: app.kcm("kcm_touchpad") } }
        }
    }
    Component {
        id: desktopPage
        ColumnLayout {
            spacing: 18
            R.SettingsGroup {
                title: qsTr("Keyboard shortcuts")
                R.SettingsRow { label: qsTr("Spotlight"); detail: "⌘ Space" }
                R.SettingsRow { label: qsTr("Launchpad"); detail: "F4" }
                R.SettingsRow { label: qsTr("Switch apps"); detail: "⌘ Tab" }
                R.SettingsRow { label: qsTr("Mission Control"); detail: "⌃ ↑" }
                R.SettingsRow { label: qsTr("Screenshot"); detail: "⇧ ⌘ 3 / 4 / 5" }
                R.SettingsRow { label: qsTr("Lock Screen"); detail: "⌃ ⌘ Q"; last: true }
            }
            R.SettingsGroup {
                R.SettingsRow { label: qsTr("Spaces (virtual desktops)"); chevron: true; onClicked: app.kcm("kcm_kwin_virtualdesktops") }
                R.SettingsRow { label: qsTr("Window behaviour"); chevron: true; last: true; onClicked: app.kcm("kcm_kwinoptions") }
            }
        }
    }
    // Pages that live in KDE's settings for now: a short description and one button
    Component {
        id: linkPage
        ColumnLayout {
            id: lp
            spacing: 18
            readonly property var map: ({
                network: ["kcm_networkmanagement", qsTr("Wired, VPN and proxy connections.")],
                notifications: ["kcm_notifications", qsTr("Choose which apps can show banners and play sounds.")],
                battery: ["kcm_powerdevilprofilesconfig", qsTr("Sleep, screen-off timing and power modes.")],
                lock: ["kcm_screenlocker", qsTr("When the screen locks and what it shows.")],
                privacy: ["kcm_firewall", qsTr("Firewall, app permissions and location. Ravana's firewall is on by default.")],
                users: ["kcm_users", qsTr("Accounts, passwords and who can use this computer.")],
                keyboard: ["kcm_keyboard", qsTr("Layouts, key repeat and input sources.")],
                mouse: ["kcm_mouse", qsTr("Pointer speed, scrolling and buttons.")],
                gaming: ["kcm_gamecontroller", qsTr("Controllers and Game Mode. Steam's Game Mode is in the Ravana menu.")]
            })
            readonly property var entry: map[app.page] || ["", ""]
            R.SettingsGroup {
                R.SettingsRow { label: lp.entry[1] || ""; last: true }
            }
            RowLayout { Item { Layout.fillWidth: true }
                R.PushButton { text: qsTr("Open…"); primary: true; onClicked: app.kcm(lp.entry[0]) } }
        }
    }
}
