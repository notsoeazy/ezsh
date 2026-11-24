import QtQuick
import Quickshell.Widgets

import qs
import qs.themes

Item {
    id: root

    readonly property bool pressed: mouseArea.pressed

    property real value: 0
    property real displayedValue: root.value
    property string icon: ""
    property bool interactive: true

    signal valueRequested(real value)
    signal stepRequested(real direction)

    readonly property int defaultWidth: 224
    readonly property int defaultHeight: 28

    implicitWidth: root.defaultWidth
    implicitHeight: root.defaultHeight

    Accessible.role: Accessible.Slider
    Accessible.name: root.icon
    Accessible.description: `${Math.round(root.value * 100)}%`

    ClippingRectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.color.m3surfaceContainerHighest

        StyledRectangle {
            // Overshoot past either end is clipped by the pill.
            width: Math.max(0, root.displayedValue) * parent.width
            height: parent.height
            color: Theme.color.m3primary
        }
    }

    StyledIcon {
        id: icon

        x: (root.height - width) / 2 + Tokens.spacing.xxs
        anchors.verticalCenter: parent.verticalCenter
        iconSize: Tokens.icon.md
        fillAmount: 1
        text: root.icon
        color: root.displayedValue * root.width >= icon.x + icon.width ? Theme.color.m3onPrimary : Theme.color.m3onSurface
        visible: root.icon !== ""
    }

    WheelArea {
        id: mouseArea

        function valueFromX(x) {
            return Math.max(0, Math.min(1, x / root.width));
        }

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor

        onPressed: event => root.valueRequested(mouseArea.valueFromX(event.x))
        onPositionChanged: event => {
            if (mouseArea.pressed)
                root.valueRequested(mouseArea.valueFromX(event.x));
        }
        onStepped: direction => root.stepRequested(direction)
    }

    Behavior on displayedValue {
        enabled: !mouseArea.pressed

        Anim {
            duration: Tokens.animDuration.spatialFast
            easing.type: Easing.OutBack
        }
    }
}
