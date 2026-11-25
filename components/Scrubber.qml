import QtQuick

import qs
import qs.themes

Item {
    id: root

    property real value: 0 // 0..1
    property bool interactive: true
    property int glideDuration: 0
    property real dragValue: 0
    property bool settling: false
    property real animatedValue: root.value
    property bool gliding: false

    readonly property int defaultHeight: 16
    readonly property int trackHeight: 4
    readonly property int thumbSize: 10
    readonly property int thumbPressedSize: 14
    readonly property int settleTime: 1000
    readonly property real maxGlideStep: 0.05
    readonly property bool pressed: mouseArea.pressed
    readonly property real shownValue: Math.max(0, Math.min(1, root.pressed || root.settling ? root.dragValue : root.animatedValue))

    signal seekRequested(real value)
    signal stepRequested(int direction)

    implicitHeight: root.defaultHeight

    Accessible.role: Accessible.Slider
    Accessible.description: `${Math.round(root.value * 100)}%`

    onValueChanged: {
        if (root.settling && Math.abs(root.value - root.dragValue) <= 0.01)
            root.settling = false;
        root.gliding = root.glideDuration > 0 && Math.abs(root.value - root.animatedValue) <= root.maxGlideStep;
        root.animatedValue = root.value;
    }

    Behavior on animatedValue {
        enabled: !root.pressed && !root.settling

        Anim {
            duration: root.gliding ? root.glideDuration : Tokens.animDuration.effectsFast
            easing.type: root.gliding ? Easing.Linear : Easing.OutCubic
        }
    }

    Timer {
        id: settleTimer

        interval: root.settleTime
        onTriggered: root.settling = false
    }

    StyledRectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.trackHeight
        radius: Tokens.radius.full
        color: Theme.color.m3surfaceContainerHighest

        StyledRectangle {
            width: root.shownValue * parent.width
            height: parent.height
            radius: Tokens.radius.full
            color: Theme.color.m3primary
            visible: root.interactive || root.value > 0
        }
    }

    StyledRectangle {
        property real diameter: root.pressed ? root.thumbPressedSize : root.thumbSize

        x: root.shownValue * (root.width - width)
        anchors.verticalCenter: parent.verticalCenter
        width: diameter
        height: diameter
        radius: Tokens.radius.full
        color: Theme.color.m3primary
        visible: root.interactive

        Behavior on diameter {
            Anim {
                duration: Tokens.animDuration.effectsFast
            }
        }
    }

    WheelArea {
        id: mouseArea

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        function valueFromX(x) {
            return Math.max(0, Math.min(1, x / root.width));
        }

        onPressed: event => {
            root.settling = false;
            settleTimer.stop();
            root.dragValue = mouseArea.valueFromX(event.x);
        }
        onPositionChanged: event => {
            if (mouseArea.pressed)
                root.dragValue = mouseArea.valueFromX(event.x);
        }
        onReleased: {
            root.settling = true;
            settleTimer.restart();
            root.seekRequested(root.dragValue);
        }
        onStepped: direction => root.stepRequested(direction)
    }
}
