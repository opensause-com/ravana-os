/*
 * Ravana menu: the crown at the left of the top bar.
 * One click opens the system menu (like the Apple menu on macOS).
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    toolTipMainText: i18n("Ravana menu")
    toolTipSubText: i18n("About, settings, sleep, restart and shut down")

    readonly property string logout: "dbus-send --session --type=method_call --dest=org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt."

    P5Support.DataSource {
        id: shell
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => disconnectSource(source)
        function run(cmd) { connectSource(cmd) }
    }

    function openMenu() {
        menu.visualParent = button
        menu.openRelative()
    }

    Plasmoid.onActivated: openMenu()

    // Size hints on the root item, like KDE's own panel buttons
    readonly property int buttonSize: Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.largeSpacing
    Layout.minimumWidth: buttonSize
    Layout.preferredWidth: buttonSize
    Layout.maximumWidth: buttonSize
    Layout.minimumHeight: Kirigami.Units.iconSizes.smallMedium
    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium

    MouseArea {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.openMenu()
        Accessible.name: i18n("Ravana menu")
        Accessible.role: Accessible.ButtonMenu

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
            width: Kirigami.Units.iconSizes.smallMedium
            height: width
            source: "ravana-logo"
        }
    }

    PlasmaExtras.Menu {
        id: menu
        placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup

        PlasmaExtras.MenuItem {
            text: i18n("About This Computer")
            icon: "help-about"
            onClicked: shell.run("kinfocenter")
        }
        PlasmaExtras.MenuItem { separator: true }
        PlasmaExtras.MenuItem {
            text: i18n("System Settings…")
            icon: "preferences-system"
            onClicked: shell.run("systemsettings")
        }
        PlasmaExtras.MenuItem {
            text: i18n("App Store…")
            icon: "system-software-install"
            onClicked: shell.run("sh -c 'gtk-launch io.github.kolunmi.Bazaar || plasma-discover'")
        }
        PlasmaExtras.MenuItem {
            text: i18n("Software Update…")
            icon: "system-software-update"
            onClicked: shell.run("gtk-launch ravana-update")
        }
        PlasmaExtras.MenuItem { separator: true }
        PlasmaExtras.MenuItem {
            text: i18n("Force Quit…")
            icon: "application-exit"
            onClicked: shell.run("dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.killWindow")
        }
        PlasmaExtras.MenuItem { separator: true }
        PlasmaExtras.MenuItem {
            text: i18n("Sleep")
            icon: "system-suspend"
            onClicked: shell.run("systemctl suspend")
        }
        PlasmaExtras.MenuItem {
            text: i18n("Restart…")
            icon: "system-reboot"
            onClicked: shell.run(root.logout + "promptReboot")
        }
        PlasmaExtras.MenuItem {
            text: i18n("Shut Down…")
            icon: "system-shutdown"
            onClicked: shell.run(root.logout + "promptShutDown")
        }
        PlasmaExtras.MenuItem { separator: true }
        PlasmaExtras.MenuItem {
            text: i18n("Lock Screen")
            icon: "system-lock-screen"
            onClicked: shell.run("loginctl lock-session")
        }
        PlasmaExtras.MenuItem {
            text: i18n("Log Out…")
            icon: "system-log-out"
            onClicked: shell.run(root.logout + "promptLogout")
        }
    }
}
