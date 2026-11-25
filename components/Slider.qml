import QtQuick
import Quickshell.Widgets

import qs
import qs.themes

Item {
    id: root

    property real value: 0
    property real displayedValue: root.value
    property string icon: ""
    property bool interactive: true

    readonly property bool pressed: mouseArea.pressed
    readonly property int defaultWidth: 224
    readonly property int defaultHeight: 28

    signal valueRequested(real value)
    signal stepRequested(int direction)

    implicitWidth: root.defaultWidth
    implicitHeight: root.defaultHeight

    Accessible.role: Accessible.Slider
    Accessible.name: root.icon
    Accessible.description: `${Math.round(root.value * 100)}%`

    Behavior on displayedValue {
        enabled: !mouseArea.pressed

        Anim {
            duration: Tokens.animDuration.spatialFast
            easing.type: Easing.OutBack
        }
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.color.m3surfaceContainerHighest

        StyledIcon {
            id: icon

            x: (root.height - width) / 2 + Tokens.spacing.xxs
            anchors.verticalCenter: parent.verticalCenter
            iconSize: Tokens.icon.md
            fillAmount: 1
            text: root.icon
            color: Theme.color.m3onSurface
            visible: root.icon !== ""
        }

        StyledRectangle {
            // Overshoot past either end is clipped by the pill.
            width: Math.max(0, root.displayedValue) * parent.width
            height: parent.height
            color: Theme.color.m3primary
            // The icon again in the on-fill colour, cut off where the fill ends.
            clip: true

            StyledIcon {
                x: icon.x
                y: icon.y
                iconSize: icon.iconSize
                fillAmount: 1
                text: root.icon
                color: Theme.color.m3onPrimary
                visible: icon.visible
            }
        }
    }

    WheelArea {
        id: mouseArea

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor

        function valueFromX(x) {
            return Math.max(0, Math.min(1, x / root.width));
        }

        onPressed: event => root.valueRequested(mouseArea.valueFromX(event.x))
        onPositionChanged: event => {
            if (mouseArea.pressed)
                root.valueRequested(mouseArea.valueFromX(event.x));
        }
        onStepped: direction => root.stepRequested(direction)
    }
}
