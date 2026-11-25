import QtQuick
import QtQuick.Layouts

import qs
import qs.themes

// A row of shortcuts: hints: [{ keys: ["ctrl", "z"], label: "undo" }, "spacer", ...]. A "spacer"
// takes the free width, so hints after it sit at the right edge.
RowLayout {
    id: root

    property var hints: []

    spacing: Tokens.spacing.md

    Repeater {
        model: root.hints

        Item {
            id: entry

            required property var modelData

            readonly property bool isSpacer: entry.modelData === "spacer"

            Layout.fillWidth: entry.isSpacer
            implicitWidth: entry.isSpacer ? 0 : hint.implicitWidth
            implicitHeight: hint.implicitHeight

            Row {
                id: hint

                visible: !entry.isSpacer
                spacing: Tokens.spacing.xs

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.xxs

                    Repeater {
                        model: entry.isSpacer ? [] : entry.modelData.keys

                        KeyCap {
                            id: keyCap

                            required property string modelData

                            text: keyCap.modelData
                        }
                    }
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    animateFontSize: false
                    animateTextChange: true
                    text: entry.isSpacer ? "" : entry.modelData.label
                    font.pixelSize: Tokens.fontSize.xs
                    color: Theme.color.m3onSurfaceVariant
                }
            }
        }
    }
}
