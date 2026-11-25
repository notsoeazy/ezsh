import QtQuick
import Quickshell.Widgets

import qs
import qs.themes

// One card of a Carousel: centered in its slot, enlarged and outlined while selected, its
// content clipped to the rounded corners. The delegate sets the slot's width and height.
Item {
    id: root

    required property bool selected
    required property real cardWidth
    required property real cardHeight
    property real selectedScale: 1.25
    property color color: Theme.color.m3surfaceContainerHigh
    property string accessibleName: ""
    default property alias content: contentArea.data

    property real factor: root.selected ? root.selectedScale : 1

    signal clicked()

    z: root.selected ? 1 : 0

    Accessible.role: Accessible.Button
    Accessible.name: root.accessibleName
    Accessible.onPressAction: root.clicked()

    Behavior on factor {
        Anim {
            duration: Tokens.animDuration.spatialFast
        }
    }

    ClippingRectangle {
        id: frame

        anchors.centerIn: parent
        width: root.cardWidth * root.factor
        height: root.cardHeight * root.factor
        radius: Tokens.radius.lg
        color: root.color

        Behavior on color {
            CAnim {}
        }

        Item {
            id: contentArea

            anchors.fill: parent
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }

    StyledRectangle {
        anchors.fill: frame
        radius: frame.radius
        color: "transparent"
        border.width: Tokens.stroke.thick
        border.color: Theme.color.m3primary
        opacity: root.selected ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                duration: Tokens.animDuration.effectsFast
            }
        }
    }
}
