import QtQuick

import qs
import qs.themes
import qs.components

// The card at the top of a settings page: its icon, title and what it covers.
StyledRectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string description: ""

    readonly property int circleSize: 72

    implicitHeight: column.implicitHeight + Tokens.spacing.xxxl * 2
    radius: Tokens.radius.xl
    color: Theme.color.m3surfaceContainerLow

    Column {
        id: column

        x: Tokens.spacing.xxl
        y: Tokens.spacing.xxxl
        width: root.width - Tokens.spacing.xxl * 2
        spacing: Tokens.spacing.sm

        StyledRectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.circleSize
            height: root.circleSize
            radius: Tokens.radius.full
            color: Theme.color.m3primaryContainer

            StyledIcon {
                anchors.centerIn: parent
                text: root.icon
                iconSize: Tokens.icon.xl
                fillAmount: 1
                color: Theme.color.m3onPrimaryContainer
            }
        }

        StyledText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elideText: true
            animateFontSize: false
            text: root.title
            font.pixelSize: Tokens.fontSize.xxl
            font.weight: Tokens.font.semibold
            color: Theme.color.m3onSurface
        }

        StyledText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapText: true
            animateFontSize: false
            text: root.description
            font.pixelSize: Tokens.fontSize.sm
            color: Theme.color.m3onSurfaceVariant
        }
    }
}
