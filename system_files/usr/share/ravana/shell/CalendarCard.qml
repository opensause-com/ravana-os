// Copyright (c) 2026 Ravana OS. All rights reserved.
// Month calendar widget: today in a Ravana red circle, ‹ › to change month.
import QtQuick
import QtQuick.Layouts
import Quickshell
import org.ravana.ui as R

R.Glass {
    id: cal
    implicitHeight: col.implicitHeight + 24
    SystemClock { id: clock; precision: SystemClock.Hours }
    property int offset: 0
    readonly property date month: { const d = clock.date; return new Date(d.getFullYear(), d.getMonth() + offset, 1); }
    readonly property int lead: (month.getDay() + 6) % 7                       // weeks start Monday
    readonly property int days: new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate()

    ColumnLayout {
        id: col
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 12
        spacing: 6
        RowLayout {
            Layout.fillWidth: true
            Text {
                textFormat: Text.PlainText
                Layout.fillWidth: true
                text: Qt.formatDate(cal.month, "MMMM yyyy")
                color: R.Theme.text
                font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeBody; font.weight: Font.Bold
            }
            Repeater {
                model: ["‹", "›"]
                Text {
                    textFormat: Text.PlainText
                    required property string modelData
                    required property int index
                    text: modelData
                    color: R.Theme.secondaryText
                    font.pixelSize: 18
                    leftPadding: 8
                    MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: cal.offset += index === 0 ? -1 : 1 }
                }
            }
        }
        Grid {
            Layout.fillWidth: true
            columns: 7
            readonly property real cell: width / 7
            Repeater {
                model: ["M", "T", "W", "T", "F", "S", "S"]
                Text {
                    textFormat: Text.PlainText
                    required property string modelData
                    width: parent.cell; height: 20
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: R.Theme.tertiaryText
                    font.family: R.Theme.fontFamily; font.pixelSize: R.Theme.sizeCaption; font.weight: Font.DemiBold
                }
            }
            Repeater {
                model: cal.lead + cal.days
                Item {
                    required property int index
                    readonly property int day: index - cal.lead + 1
                    readonly property bool today: cal.offset === 0 && day === clock.date.getDate()
                    width: parent.cell; height: 28
                    Rectangle {
                        anchors.centerIn: parent
                        width: 26; height: 26; radius: 13
                        color: R.Theme.accent
                        visible: parent.today
                    }
                    Text {
                        textFormat: Text.PlainText
                        anchors.centerIn: parent
                        visible: parent.day > 0
                        text: parent.day
                        color: parent.today ? R.Theme.textOnAccent : R.Theme.text
                        font.family: R.Theme.fontFamily; font.pixelSize: 12
                        font.weight: parent.today ? Font.Bold : Font.Normal
                    }
                }
            }
        }
    }
}
