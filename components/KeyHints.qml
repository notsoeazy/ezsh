import QtQuick

import qs
import qs.themes
import qs.components

Item {
    id: root

    property var hints: []
    property string escapeLabel: "close"

    readonly property int hintHeight: 20

    implicitHeight: root.hintHeight

    Hint {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        key: "esc"
        label: root.escapeLabel
    }

    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.md

        Repeater {
            model: root.hints

            Hint {
                required property var modelData

                key: modelData.key
                label: modelData.label
            }
        }
    }

    component Hint: Row {
        property string key: ""
        property string label: ""

        spacing: Tokens.spacing.xxs

        StyledText {
            animateFontSize: false
            text: parent.key
            font.pixelSize: Tokens.fontSize.xs
            font.weight: Tokens.font.semibold
            color: Theme.color.m3onSurface
        }

        StyledText {
            animateFontSize: false
            animateTextChange: true
            text: parent.label
            font.pixelSize: Tokens.fontSize.xs
            color: Theme.color.m3onSurfaceVariant
        }
    }
}
