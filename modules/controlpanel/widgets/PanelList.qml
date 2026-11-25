import QtQuick
import Quickshell

import qs
import qs.components

// The scrolling body of a control panel list page
Flickable {
    id: root

    property var sections: []
    property var headline: item => ""
    property var supportingText: item => ""
    property var leadingIcon: item => ""
    property var trailingIcon: item => ""
    property var isSelected: item => false
    // Rows are a pick-one list: a radio per row, checked where isChecked.
    property bool radios: false
    property var isChecked: item => false
    // Rows above the sections that aren't items of a section (the Ethernet row).
    default property alias content: extraRows.data

    readonly property int maxHeight: 320
    readonly property int rowGap: 2

    signal activated(var item)

    implicitHeight: Math.min(root.maxHeight, root.contentHeight)
    contentWidth: width
    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: column

        width: root.width
        spacing: Tokens.spacing.md

        Column {
            id: extraRows

            width: parent.width
            visible: visibleChildren.length > 0
            spacing: root.rowGap
        }

        // By count, not by the array: `sections` is rebuilt on every change, and a section must
        // outlive that so its ScriptModel can keep its rows.
        Repeater {
            model: root.sections.length

            Column {
                id: section

                required property int index
                readonly property string title: root.sections[section.index]?.title ?? ""
                readonly property var values: root.sections[section.index]?.values ?? []

                width: column.width
                visible: section.values.length > 0
                spacing: Tokens.spacing.xs

                SectionHeader {
                    visible: section.title !== ""
                    text: section.title
                }

                Column {
                    width: parent.width
                    spacing: root.rowGap

                    Repeater {
                        id: rows

                        // A ScriptModel keeps rows alive across re-sorts instead of recreating them all.
                        model: ScriptModel {
                            values: section.values
                        }

                        ListItem {
                            id: row

                            required property var modelData
                            required property int index

                            width: column.width
                            first: row.index === 0
                            last: row.index === rows.count - 1
                            icon: root.leadingIcon(row.modelData)
                            headline: root.headline(row.modelData)
                            supportingText: root.supportingText(row.modelData)
                            trailingIcon: root.trailingIcon(row.modelData)
                            selected: root.isSelected(row.modelData)
                            radio: root.radios
                            checked: root.radios && root.isChecked(row.modelData)
                            onClicked: root.activated(row.modelData)
                        }
                    }
                }
            }
        }
    }
}
