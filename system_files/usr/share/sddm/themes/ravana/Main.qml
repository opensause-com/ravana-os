// Copyright (c) 2026 Ravana OS. All rights reserved.
// Ravana login (SDDM theme): the wallpaper as it is, a round avatar and name in the
// middle, a frosted capsule "Enter Password" field with a round arrow, other users
// beside, time and keyboard layout top right, Shut Down / Restart / Sleep at the bottom.
// Signing in is SDDM's own (sddm.login); this file is only the look.
import QtQuick
import QtQuick.Effects

Rectangle {
    id: root
    width: 1920; height: 1080
    color: "#0b0a0c"

    readonly property string fontFamily: "Inter"
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string userName: ""
    property string realName: ""
    property string userIcon: ""

    // ---- wallpaper: sharp, with a light veil ----
    Image {
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        sourceSize: Qt.size(root.width, root.height)
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.18) }

    // ---- top right: keyboard layout and time ----
    Row {
        anchors.top: parent.top; anchors.right: parent.right
        anchors.topMargin: 8; anchors.rightMargin: 16
        spacing: 16
        Text {
            visible: keyboard.layouts.length > 1
            text: keyboard.layouts.length > 0 ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : ""
            color: "white"; font.family: root.fontFamily; font.pixelSize: 13; font.weight: Font.DemiBold
            MouseArea { anchors.fill: parent; onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length }
        }
        Text {
            id: clock
            property date now: new Date()
            Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.now = new Date() }
            text: Qt.formatDate(now, "ddd d MMM") + "   " + Qt.formatTime(now, Qt.locale().timeFormat(Locale.ShortFormat))
            color: "white"; font.family: root.fontFamily; font.pixelSize: 13; font.weight: Font.Medium
        }
    }

    // ---- users: the chosen one in the middle, others small beside ----
    // Same geometry as the Ravana lock screen: 120 px avatar centred at 43 % of the
    // height, the name 22 px below it, the 200 x 30 capsule at 57 %.
    readonly property int avatarSize: 120
    ListView {
        id: users
        model: userModel
        currentIndex: root.userIndex
        orientation: ListView.Horizontal
        interactive: false
        spacing: 36
        width: Math.min(root.width - 80, count * 160 + (count - 1) * 36)
        height: root.avatarSize + 60
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(root.height * 0.4324 - root.avatarSize / 2)
        delegate: Item {
            id: person
            required property int index
            required property string name
            required property string realName
            required property string icon
            readonly property bool current: ListView.isCurrentItem
            // SDDM's stock face means "no photo set": draw Ravana's default instead
            readonly property bool hasPhoto: icon.length > 0 && icon.indexOf("/usr/share/sddm/faces/") !== 0
            width: 160; height: users.height
            opacity: current ? 1 : 0.6
            scale: current ? 1 : 0.75
            transformOrigin: Item.Top
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
            Behavior on opacity { NumberAnimation { duration: 220 } }
            onCurrentChanged: if (current) { root.userName = name; root.realName = realName || name; root.userIcon = icon; }
            Component.onCompleted: if (current) { root.userName = name; root.realName = realName || name; root.userIcon = icon; }

            Rectangle {       // white rim
                id: avatar
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.avatarSize; height: width; radius: width / 2
                color: "white"
                Rectangle {   // default: white figure on Ravana red
                    id: fallback
                    anchors.fill: parent; anchors.margins: 3
                    radius: width / 2
                    color: "#d21f3c"
                    visible: !person.hasPhoto || face.status !== Image.Ready
                    clip: true
                    Rectangle {   // head
                        width: parent.width * 0.30; height: width; radius: width / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.height * 0.24
                        color: "white"
                    }
                    Rectangle {   // shoulders
                        width: parent.width * 0.56; height: parent.height * 0.34
                        radius: width * 0.42
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.height * 0.58
                        color: "white"
                    }
                }
                Image {
                    id: face
                    anchors.fill: parent; anchors.margins: 3
                    source: person.hasPhoto ? person.icon : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(240, 240)
                    visible: false
                }
                Rectangle {
                    id: faceMask
                    anchors.fill: face
                    radius: width / 2
                    visible: false
                    layer.enabled: true
                }
                MultiEffect {           // the photo, cut to a circle
                    anchors.fill: face
                    source: face
                    maskEnabled: true
                    maskSource: faceMask
                    visible: person.hasPhoto && face.status === Image.Ready
                }
            }
            Text {
                anchors.top: avatar.bottom; anchors.topMargin: 22
                anchors.horizontalCenter: parent.horizontalCenter
                text: person.realName || person.name
                color: "white"; font.family: root.fontFamily; font.pixelSize: 18
            }
            MouseArea { anchors.fill: parent; onClicked: { root.userIndex = person.index; password.forceActiveFocus(); } }
        }
    }

    // ---- password capsule (exactly centred; the arrow sits outside it on the right) ----
    Item {
        id: passwordRow
        width: 200; height: 30
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(root.height * 0.567)
        property real shake: 0
        transform: Translate { x: passwordRow.shake }
        SequentialAnimation {
            id: shakeAnim
            loops: 2
            NumberAnimation { target: passwordRow; property: "shake"; to: -10; duration: 50 }
            NumberAnimation { target: passwordRow; property: "shake"; to: 10; duration: 80 }
            NumberAnimation { target: passwordRow; property: "shake"; to: 0; duration: 50 }
        }

        Rectangle {
            id: capsule
            anchors.fill: parent
            radius: 15
            color: Qt.rgba(1, 1, 1, password.activeFocus ? 0.26 : 0.18)
            border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.25)
            TextInput {
                id: password
                anchors.fill: parent
                anchors.leftMargin: 14; anchors.rightMargin: 14
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                echoMode: TextInput.Password
                passwordCharacter: "\u25cf"
                cursorVisible: activeFocus && text.length > 0
                color: "white"
                font.family: root.fontFamily; font.pixelSize: 13
                focus: true
                clip: true
                Keys.onReturnPressed: root.login()
                Keys.onEnterPressed: root.login()
                Keys.onLeftPressed: event => { if (!text && root.userIndex > 0) root.userIndex--; else event.accepted = false; }
                Keys.onRightPressed: event => { if (!text && root.userIndex < users.count - 1) root.userIndex++; else event.accepted = false; }
            }
            Text {
                anchors.centerIn: parent
                visible: !password.text
                text: "Enter Password"
                color: Qt.rgba(1, 1, 1, 0.6)
                font.family: root.fontFamily; font.pixelSize: 13
            }
        }
        Rectangle {      // round arrow, outside the capsule so the capsule stays centred
            anchors.left: capsule.right; anchors.leftMargin: 6
            anchors.verticalCenter: capsule.verticalCenter
            width: 30; height: 30; radius: 15
            visible: password.text.length > 0
            color: Qt.rgba(1, 1, 1, arrowArea.containsMouse ? 0.32 : 0.18)
            border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.25)
            Text { anchors.centerIn: parent; text: "\u2192"; color: "white"; font.pixelSize: 15 }
            MouseArea { id: arrowArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.login() }
        }
    }
    Text {
        id: message
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: passwordRow.bottom; anchors.topMargin: 14
        color: "white"
        font.family: root.fontFamily; font.pixelSize: 12; font.weight: Font.Medium
        text: keyboard.capsLock ? "Caps Lock is on" : ""
    }

    function login() {
        if (!password.text) return;
        message.text = "";
        sddm.login(root.userName, password.text, root.sessionIndex);
    }
    Connections {
        target: sddm
        function onLoginFailed() {
            password.text = "";
            message.text = "Incorrect password";
            shakeAnim.restart();
            password.forceActiveFocus();
        }
    }

    // ---- Shut Down / Restart / Sleep ----
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(root.height * 0.06)
        spacing: 44
        Repeater {
            model: [
                { label: "Shut Down", glyph: "⏻", act: 0, show: true },
                { label: "Restart", glyph: "↻", act: 1, show: true },
                { label: "Sleep", glyph: "☾", act: 2, show: true }
            ]
            Column {
                id: power
                required property var modelData
                visible: modelData.show
                spacing: 8
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 44; height: 44; radius: 22
                    color: Qt.rgba(1, 1, 1, powerArea.containsMouse ? 0.30 : 0.18)
                    border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.25)
                    Text { anchors.centerIn: parent; text: power.modelData.glyph; color: "white"; font.pixelSize: 18 }
                    MouseArea {
                        id: powerArea
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: power.modelData.act === 0 ? sddm.powerOff() : power.modelData.act === 1 ? sddm.reboot() : sddm.suspend()
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: power.modelData.label
                    color: "white"; font.family: root.fontFamily; font.pixelSize: 12; font.weight: Font.Medium
                }
            }
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
