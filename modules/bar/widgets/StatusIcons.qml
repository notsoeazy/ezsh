import QtQuick

import qs
import qs.themes
import qs.services
import qs.components

Row {
    id: root
    spacing: -2

    // The notification count; the expanded bar shows its own summary instead.
    property bool showNotificationCount: true

    signal navigateRequested(string view, string page)

    Reveal {
        anchors.verticalCenter: parent.verticalCenter
        revealed: root.showNotificationCount && NotificationService.count > 0
        trailingGap: Tokens.spacing.xxs

        StyledRectangle {
            implicitWidth: Math.max(implicitHeight, countLabel.implicitWidth + Tokens.spacing.xs)
            implicitHeight: Tokens.icon.md
            radius: Tokens.radius.full
            color: Theme.color.m3primary

            StyledText {
                id: countLabel

                anchors.centerIn: parent
                text: NotificationService.count > 99 ? "99+" : NotificationService.count
                font.pixelSize: Tokens.fontSize.xs
                font.weight: Tokens.font.semibold
                color: Theme.color.m3onPrimary
            }
        }
    }

    Reveal {
        anchors.verticalCenter: parent.verticalCenter
        revealed: NotificationService.doNotDisturb

        Button {
            type: "standard"
            buttonHeight: Tokens.bar.iconButtonSize
            iconSize: Tokens.icon.md
            iconFilled: true
            icon: "notifications_off"
        }
    }

    Button {
        type: "standard"
        buttonHeight: Tokens.bar.iconButtonSize
        iconSize: Tokens.icon.md
        iconFilled: true
        icon: AudioService.micIcon
        contentColor: AudioService.micInUse && AudioService.micMuted ? Theme.color.m3tertiary : Theme.color.m3onSurface
        onClicked: AudioService.toggleMicMute()
        onSecondaryClicked: root.navigateRequested("controlpanel", "audio")
    }

    Button {
        type: "standard"
        buttonHeight: Tokens.bar.iconButtonSize
        iconSize: Tokens.icon.md
        iconFilled: true
        icon: AudioService.volumeIcon
        contentColor: AudioService.outputMuted ? Theme.color.m3outline : Theme.color.m3onSurface
        onClicked: AudioService.toggleOutputMute()
    }

    Button {
        type: "standard"
        buttonHeight: Tokens.bar.iconButtonSize
        iconSize: Tokens.icon.md
        iconFilled: true
        icon: NetworkService.icon
        contentColor: NetworkService.online ? Theme.color.m3onSurface : Theme.color.m3outline
        onClicked: root.navigateRequested("controlpanel", "")
    }

    Button {
        type: "standard"
        visible: BatteryService.available
        buttonHeight: Tokens.bar.iconButtonSize
        iconSize: Tokens.icon.md
        iconFilled: true
        icon: BatteryService.icon
        contentColor: BatteryService.low ? Theme.color.m3error : Theme.color.m3onSurface
        onClicked: root.navigateRequested("controlpanel", "battery")
    }
}
