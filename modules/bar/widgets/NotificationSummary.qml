import QtQuick

import qs
import qs.themes
import qs.services
import qs.components

// "All caught up" / "N notifications" + bell, right-aligned.
Item {
    id: root

    implicitWidth: label.implicitWidth + Tokens.spacing.xs + bell.implicitWidth
    implicitHeight: Math.max(label.implicitHeight, bell.implicitHeight)

    StyledText {
        id: label

        anchors {
            left: parent.left
            right: bell.left
            rightMargin: Tokens.spacing.xs
            verticalCenter: parent.verticalCenter
        }

        horizontalAlignment: Text.AlignRight
        elideText: true
        animateText: true
        text: NotificationService.summary
        font.pixelSize: Tokens.fontSize.sm
        color: Theme.color.m3onSurface
    }

    // Same button footprint as StatusIcons so the bell lines up with them.
    IconButton {
        id: bell

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        buttonSize: Tokens.bar.iconButton
        iconSize: Tokens.icon.md
        icon: NotificationService.icon
    }
}
