/*
 * Ravana Search: magnifier in the top bar that opens KRunner
 * (centered search for apps, files, settings, maths and the web), like Spotlight.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    toolTipMainText: i18n("Search")
    toolTipSubText: i18n("Apps, files, settings and more (Meta+Space)")

    P5Support.DataSource {
        id: shell
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => disconnectSource(source)
    }

    function toggle() {
        shell.connectSource("dbus-send --session --type=method_call --dest=org.kde.krunner /App org.kde.krunner.App.toggleDisplay")
    }

    Plasmoid.onActivated: toggle()

    compactRepresentation: MouseArea {
        id: button
        Layout.minimumWidth: Kirigami.Units.iconSizes.small + Kirigami.Units.largeSpacing
        Layout.maximumWidth: Layout.minimumWidth
        hoverEnabled: true
        onClicked: root.toggle()

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: 5
            color: Kirigami.Theme.textColor
            opacity: button.containsMouse ? 0.12 : 0
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
        }

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.small
            height: width
            source: "search-symbolic"
            fallback: "search"
        }
    }
}
