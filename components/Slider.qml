import QtQuick
import Quickshell.Widgets

import qs
import qs.themes

// A pill-shaped level slider with an icon inside its start. The owner keeps `value` (0..1);
// the slider only reports input: moved(value) while dragging, stepped(±1) per wheel notch.
Item {
    id: root

    property real value: 0
    property string icon: ""
    property bool interactive: true
    readonly property bool pressed: mouse.pressed

    signal moved(real value)
    signal stepped(real direction)

    // What is drawn: follows the pointer exactly while dragging, otherwise springs to `value`.
    property real shown: root.value

    Behavior on shown {
        enabled: !mouse.pressed

        Anim {
            duration: Tokens.animDuration.spatialFast
            easing.type: Easing.OutBack
        }
    }

    implicitWidth: Tokens.osd.sliderWidth
    implicitHeight: Tokens.osd.sliderHeight

    Accessible.role: Accessible.Slider
    Accessible.name: root.icon
    Accessible.description: `${Math.round(root.value * 100)}%`

    ClippingRectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.color.m3surfaceContainerHighest

        Rectangle {
            // Overshoot past either end is clipped by the pill.
            width: Math.max(0, root.shown) * parent.width
            height: parent.height
            color: Theme.color.m3primary
        }
    }

    StyledIcon {
        id: icon

        x: (root.height - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        iconSize: Tokens.icon.sm
        fill: 1
        text: root.icon
        // Dark on the fill, light on the empty track.
        color: root.shown * root.width >= icon.x + icon.width ? Theme.color.m3onPrimary : Theme.color.m3onSurface
        visible: root.icon !== ""
    }

    MouseArea {
        id: mouse

        // Accumulated wheel delta so touchpads step once per notch, not per event.
        property real wheel: 0

        function valueAt(x) {
            return Math.max(0, Math.min(1, x / root.width));
        }

        anchors.fill: parent
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor

        onPressed: event => root.moved(mouse.valueAt(event.x))
        onPositionChanged: event => {
            if (mouse.pressed)
                root.moved(mouse.valueAt(event.x));
        }
        onWheel: event => {
            mouse.wheel += event.angleDelta.y;
            if (Math.abs(mouse.wheel) < 120)
                return;
            root.stepped(mouse.wheel > 0 ? 1 : -1);
            mouse.wheel = 0;
        }
    }
}
