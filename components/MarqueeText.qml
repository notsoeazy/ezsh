import QtQuick
import QtQuick.Effects

import qs
import qs.themes

Item {
    id: root

    property string text
    property int pixelSize: Tokens.fontSize.sm
    property int weight: Tokens.font.regular
    property color color: Theme.color.m3onSurface
    property real leftFade: label.x < 0 ? 1 : 0

    readonly property int speed: 30 // px/s
    readonly property int pause: 2000
    readonly property int gap: Tokens.spacing.xxxl
    readonly property int fadeWidth: Tokens.spacing.xl

    readonly property bool overflows: label.implicitWidth > root.width
    readonly property real loopDistance: label.implicitWidth + root.gap

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight
    clip: true

    layer.enabled: root.overflows
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: fadeMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }

    Accessible.role: Accessible.StaticText
    Accessible.name: root.text

    onTextChanged: {
        label.x = 0;
        if (scroll.running)
            scroll.restart();
    }

    Behavior on leftFade {
        Anim {
            duration: Tokens.animDuration.effects
        }
    }

    StyledText {
        id: label

        animateFontSize: false
        text: root.text
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        color: root.color
    }

    StyledText {
        x: label.x + root.loopDistance
        visible: root.overflows
        animateFontSize: false
        text: root.text
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        color: root.color
    }

    Rectangle {
        id: fadeMask

        readonly property real edge: root.fadeWidth / Math.max(1, root.width)

        width: root.width
        height: root.height
        visible: false
        layer.enabled: true

        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: Qt.alpha("white", 1 - root.leftFade)
            }

            GradientStop {
                position: fadeMask.edge
                color: "white"
            }

            GradientStop {
                position: 1 - fadeMask.edge
                color: "white"
            }

            GradientStop {
                position: 1
                color: Qt.alpha("white", 0)
            }
        }
    }

    SequentialAnimation {
        id: scroll

        running: root.overflows && root.visible
        loops: Animation.Infinite

        onRunningChanged: {
            if (!scroll.running)
                label.x = 0;
        }

        PauseAnimation {
            duration: root.pause
        }

        Anim {
            target: label
            property: "x"
            from: 0
            to: -root.loopDistance
            duration: root.loopDistance / root.speed * 1000
            easing.type: Easing.Linear
        }
    }
}
