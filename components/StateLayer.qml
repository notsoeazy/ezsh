import QtQuick

import qs
import qs.themes

Rectangle {
    id: root

    property bool hovered: false
    property bool pressed: false
    property color tint: Theme.color.m3onSurface

    anchors.fill: parent
    topLeftRadius: parent.topLeftRadius
    topRightRadius: parent.topRightRadius
    bottomLeftRadius: parent.bottomLeftRadius
    bottomRightRadius: parent.bottomRightRadius
    color: root.tint
    opacity: !root.enabled ? 0 : root.pressed ? Tokens.opacity.pressed : root.hovered ? Tokens.opacity.hover : 0

    Behavior on opacity {
        Anim {
            duration: Tokens.animDuration.effectsFast
        }
    }
}
