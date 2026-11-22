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

    Reveal {
        anchors.verticalCenter: parent.verticalCenter
        shown: root.showNotificationCount && NotificationService.count > 0
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
        shown: NotificationService.doNotDisturb

        IconButton {
            buttonSize: Tokens.bar.iconButton
            iconSize: Tokens.icon.md
            selected: true // filled glyphs, per design
            icon: "notifications_off"
        }
    }

    IconButton {
        buttonSize: Tokens.bar.iconButton
        iconSize: Tokens.icon.md
        selected: true // filled glyphs, per design
        icon: AudioService.micIcon
        iconColor: AudioService.micInUse && AudioService.micMuted ? Theme.color.m3tertiary : Theme.color.m3onSurface
        onActivated: AudioService.toggleMicMute()
    }

    IconButton {
        buttonSize: Tokens.bar.iconButton
        iconSize: Tokens.icon.md
        selected: true // filled glyphs, per design
        icon: AudioService.volumeIcon
        iconColor: AudioService.muted ? Theme.color.m3outline : Theme.color.m3onSurface
        onActivated: AudioService.toggleMute()
    }

    IconButton {
        buttonSize: Tokens.bar.iconButton
        iconSize: Tokens.icon.md
        selected: true // filled glyphs, per design
        icon: NetworkService.icon
        iconColor: NetworkService.connected ? Theme.color.m3onSurface : Theme.color.m3outline
    }

    IconButton {
        visible: BatteryService.available
        buttonSize: Tokens.bar.iconButton
        iconSize: Tokens.icon.md
        selected: true // filled glyphs, per design
        icon: BatteryService.icon
        iconColor: BatteryService.low ? Theme.color.m3error : Theme.color.m3onSurface
    }
}
