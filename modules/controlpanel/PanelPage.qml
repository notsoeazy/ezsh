import QtQuick

import qs
import qs.themes
import qs.components

// Base of every control panel page: a header (back button, title, an `accessory` such as a Switch)
Item {
    id: root

    property string title: ""
    property bool showHeader: true
    // This is the panel's current page.
    property bool active: false
    // Current and the panel is open; lists scan only while shown.
    property bool shown: false
    // A popup (Menu) is open; Bar then takes input on the whole window, and Esc closes it (closeOverlay) before going back.
    property bool overlayOpen: false
    default property alias content: body.data
    property alias accessory: accessoryHolder.data

    readonly property int headerHeight: 40

    signal backRequested()
    signal pageRequested(string name)

    function closeOverlay() {
    }

    implicitHeight: column.implicitHeight

    Column {
        id: column

        width: root.width
        spacing: Tokens.spacing.md

        Item {
            width: parent.width
            height: root.headerHeight
            visible: root.showHeader

            Button {
                id: backButton

                anchors.verticalCenter: parent.verticalCenter
                type: "standard"
                icon: "chevron_left"
                Accessible.name: "Back"
                onClicked: root.backRequested()
            }

            StyledText {
                anchors {
                    left: backButton.right
                    right: accessoryHolder.left
                    leftMargin: Tokens.spacing.xs
                    rightMargin: Tokens.spacing.md
                    verticalCenter: parent.verticalCenter
                }

                elideText: true
                animateFontSize: false
                text: root.title
                font.pixelSize: Tokens.fontSize.md
                font.weight: Tokens.font.semibold
                color: Theme.color.m3onSurface
            }

            Item {
                id: accessoryHolder

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: childrenRect.width
                height: childrenRect.height
            }
        }

        Column {
            id: body

            width: parent.width
            spacing: Tokens.spacing.sm
        }
    }
}
