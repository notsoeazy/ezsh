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
    // A thin track with a bar handle (settings), instead of the filled pill (bar, panel, OSD); no icon.
    property bool thin: false

    readonly property bool pressed: mouseArea.pressed
    readonly property int defaultWidth: 224
    readonly property int defaultHeight: 28
    readonly property int thinTrackHeight: 6
    readonly property int handleWidth: 4
    readonly property int pressedHandleWidth: 2
    // Space between the handle and the track on either side of it.
    readonly property int handleGap: 6

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
        visible: !root.thin
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

    Item {
        id: thinSlider

        readonly property real handleX: Math.max(0, Math.min(1, root.displayedValue)) * (root.width - root.handleWidth)
        readonly property real trackY: (root.height - root.thinTrackHeight) / 2

        anchors.fill: parent
        visible: root.thin

        StyledRectangle {
            y: thinSlider.trackY
            width: Math.max(0, thinSlider.handleX - root.handleGap)
            height: root.thinTrackHeight
            radius: Tokens.radius.full
            color: Theme.color.m3primary
        }

        StyledRectangle {
            x: thinSlider.handleX + root.handleWidth + root.handleGap
            y: thinSlider.trackY
            width: Math.max(0, root.width - x)
            height: root.thinTrackHeight
            radius: Tokens.radius.full
            color: Theme.color.m3secondaryContainer
        }

        StyledRectangle {
            property real pressedWidth: mouseArea.pressed ? root.pressedHandleWidth : root.handleWidth

            x: thinSlider.handleX + (root.handleWidth - width) / 2
            width: pressedWidth
            height: root.height
            radius: Tokens.radius.full
            color: Theme.color.m3primary

            Behavior on pressedWidth {
                Anim {
                    duration: Tokens.animDuration.effectsFast
                }
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
