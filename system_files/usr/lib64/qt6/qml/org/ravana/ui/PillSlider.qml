// Ravana UI kit: wide pill slider with the icon inside the track (Control Center style).
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: slider
    property string iconName
    property real value: 0.5            // 0..1
    property bool available: true
    signal moved(real value)            // while dragging
    signal released(real value)         // when let go

    implicitHeight: 28
    opacity: available ? 1 : 0.45

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.sliderTrack
        clip: true

        Rectangle {
            id: fill
            height: parent.height
            width: Math.max(parent.height, parent.width * slider.value)
            radius: height / 2
            color: Theme.sliderFill
            Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: Theme.fast } }
        }

        Kirigami.Icon {
            anchors.verticalCenter: parent.verticalCenter
            x: 7
            width: 15; height: 15
            source: slider.iconName
            isMask: true
            color: Theme.sliderIcon
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        enabled: slider.available
        preventStealing: true
        function at(mx) { return Math.max(0, Math.min(1, mx / width)); }
        onPressed: mouse => { slider.value = at(mouse.x); slider.moved(slider.value); }
        onPositionChanged: mouse => { if (pressed) { slider.value = at(mouse.x); slider.moved(slider.value); } }
        onReleased: slider.released(slider.value)
        onWheel: wheel => {
            slider.value = Math.max(0, Math.min(1, slider.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
            slider.released(slider.value);
        }
    }
}
