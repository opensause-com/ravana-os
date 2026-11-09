// Ravana UI kit: round icon bubble (accent when on) + title + status line.
// Clicking toggles; used for Wi-Fi, Bluetooth, Focus, Appearance.
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: row
    property string iconName
    property string title
    property string status
    property bool on: false
    property bool available: true
    signal toggled()

    implicitHeight: 44
    opacity: available ? 1 : 0.45

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMedium
        color: mouse.containsMouse && row.available ? Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    Rectangle {
        id: bubble
        width: 30; height: 30; radius: 15
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        color: row.on ? Theme.accent : Theme.bubble
        Behavior on color { ColorAnimation { duration: Theme.normal } }
        Kirigami.Icon {
            anchors.centerIn: parent
            width: 16; height: 16
            source: row.iconName
            isMask: true
            color: row.on ? Theme.onAccent : Theme.text
        }
    }

    Column {
        anchors.left: bubble.right
        anchors.leftMargin: 9
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Text {
            width: parent.width
            text: row.title
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.bodySize
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            renderType: Text.NativeRendering
        }
        Text {
            width: parent.width
            text: row.status
            visible: text.length > 0
            color: Theme.secondaryText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.captionSize
            elide: Text.ElideRight
            renderType: Text.NativeRendering
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: row.available
        onClicked: row.toggled()
    }
}
