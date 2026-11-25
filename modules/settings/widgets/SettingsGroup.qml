import QtQuick

import qs
import qs.themes
import qs.components

// A titled card of setting rows, with hairlines between them.
Column {
    id: root

    property string title: ""
    property var rows: []

    spacing: Tokens.spacing.xs

    SectionHeader {
        x: 0
        width: parent.width
        visible: root.title !== ""
        text: root.title
    }

    StyledRectangle {
        width: parent.width
        height: rowColumn.implicitHeight
        radius: Tokens.radius.xl
        color: Theme.color.m3surfaceContainerLow

        Column {
            id: rowColumn

            width: parent.width

            // Rows are read by index, so a new rows array updates them in place instead of recreating them.
            Repeater {
                model: CountModel {
                    size: root.rows.length
                }

                Column {
                    id: entry

                    required property int index

                    width: rowColumn.width

                    Divider {
                        x: Tokens.spacing.lg
                        width: parent.width - Tokens.spacing.lg * 2
                        visible: entry.index > 0
                    }

                    SettingRow {
                        width: parent.width
                        // Undefined for a moment when the list shrinks, before this row is removed.
                        setting: root.rows[entry.index] ?? ({})
                    }
                }
            }
        }
    }
}
