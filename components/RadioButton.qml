import QtQuick

import qs
import qs.themes

Item {
    id: root

    property bool checked: false

    // 0 = unchecked, 1 = checked; drives the dot's size.
    property real progress: root.checked ? 1 : 0

    readonly property int targetSize: 40
    readonly property int ringSize: 20
    readonly property int ringWidth: Tokens.stroke.thick
    readonly property int dotSize: 10

    implicitWidth: root.targetSize
    implicitHeight: root.targetSize
    opacity: root.enabled ? 1 : Tokens.opacity.disabledContent

    Behavior on progress {
        Anim {
            duration: Tokens.animDuration.spatialFast
            easing.type: Easing.OutBack
        }
    }

    StyledRectangle {
        anchors.centerIn: parent
        width: root.ringSize
        height: root.ringSize
        radius: Tokens.radius.full
        color: "transparent"
        border.width: root.ringWidth
        border.color: root.checked ? Theme.color.m3primary : Theme.color.m3onSurfaceVariant
    }

    StyledRectangle {
        anchors.centerIn: parent
        width: root.dotSize * root.progress
        height: width
        radius: Tokens.radius.full
        color: Theme.color.m3primary
        visible: width > 0
    }
}
