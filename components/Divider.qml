import QtQuick

import qs.themes

Rectangle {
    id: root

    property bool vertical: false
    property bool fadeEnds: false

    readonly property int thickness: 1
    readonly property color lineColor: Theme.color.m3outlineVariant
    readonly property color endColor: root.fadeEnds ? Qt.alpha(root.lineColor, 0) : root.lineColor

    implicitWidth: root.vertical ? root.thickness : 0
    implicitHeight: root.vertical ? 0 : root.thickness

    gradient: Gradient {
        orientation: root.vertical ? Gradient.Vertical : Gradient.Horizontal

        GradientStop {
            position: 0
            color: root.endColor
        }

        GradientStop {
            position: 0.5
            color: root.lineColor
        }

        GradientStop {
            position: 1
            color: root.endColor
        }
    }
}
