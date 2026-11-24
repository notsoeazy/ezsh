import QtQuick

import qs
import qs.themes
import qs.services
import qs.components

// "All caught up" / "N notifications" + bell, right-aligned.
Item {
    id: root

    implicitWidth: summaryLabel.implicitWidth + Tokens.spacing.xs + bell.implicitWidth
    implicitHeight: Math.max(summaryLabel.implicitHeight, bell.implicitHeight)

    StyledText {
        id: summaryLabel

        anchors {
            left: parent.left
            right: bell.left
            rightMargin: Tokens.spacing.xs
            verticalCenter: parent.verticalCenter
        }

        horizontalAlignment: Text.AlignRight
        elideText: true
        animateTextChange: true
        text: NotificationService.summaryText
        font.pixelSize: Tokens.fontSize.sm
        color: Theme.color.m3onSurface
    }

    // Same button footprint as StatusIcons so the bell lines up with them.
    Button {
        type: "standard"
        id: bell

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        buttonHeight: Tokens.bar.iconButtonSize
        iconSize: Tokens.icon.md
        icon: NotificationService.icon
    }
}
