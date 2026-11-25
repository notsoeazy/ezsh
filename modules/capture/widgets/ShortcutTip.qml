import QtQuick

import qs
import qs.themes
import qs.components

// A button's name and shortcut, shown above it while hovered. Place it inside a Button.
StyledRectangle {
    id: root

    required property string label
    property var keys: []
    property real progress: root.shown ? 1 : 0

    readonly property int gap: Tokens.spacing.md
    readonly property bool shown: root.parent?.hovered ?? false

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.top
    anchors.bottomMargin: root.gap - Tokens.spacing.xxs * (1 - root.progress)
    implicitWidth: row.implicitWidth + Tokens.spacing.sm * 2
    implicitHeight: row.implicitHeight + Tokens.spacing.xs * 2
    radius: Tokens.radius.md
    color: Theme.color.m3inverseSurface
    opacity: root.progress
    visible: root.progress > 0

    Behavior on progress {
        Anim {
            duration: Tokens.animDuration.effects
        }
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.spacing.xs

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            animateFontSize: false
            text: root.label
            font.pixelSize: Tokens.fontSize.xs
            color: Theme.color.m3inverseOnSurface
        }

        Repeater {
            model: root.keys

            KeyCap {
                id: keyCap

                required property string modelData

                anchors.verticalCenter: parent.verticalCenter
                text: keyCap.modelData
                tint: Theme.color.m3inverseOnSurface
            }
        }
    }
}
