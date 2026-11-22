import QtQuick
import qs
import qs.themes

Item {
    id: root

    required property string icon
    property bool selected: false
    property real buttonSize: 32
    property int iconSize: Tokens.icon.md
    property color iconColor: Theme.color.m3onSurface

    signal activated()

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    activeFocusOnTab: true

    Accessible.role: Accessible.Button
    Accessible.name: root.icon
    Accessible.onPressAction: root.activated()

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.activated();
            event.accepted = true;
        }
    }

    StyledRectangle {
        anchors.fill: parent
        color: Theme.color.m3onSurface
        radius: mouse.pressed ? Tokens.radius.md : root.buttonSize / 2
        opacity: !root.enabled ? 0 : mouse.pressed ? Tokens.opacity.pressed : mouse.containsMouse ? Tokens.opacity.hover : 0

        Behavior on radius {
            Anim {
                duration: Tokens.animDuration.spatialFast
                easing.type: Easing.OutBack
            }
        }

        Behavior on opacity {
            Anim {
                duration: Tokens.animDuration.effectsFast
                easing.type: Easing.OutCubic
            }
        }
    }

    StyledIcon {
        anchors.centerIn: parent
        text: root.icon
        fill: root.selected ? 1 : 0
        iconSize: root.iconSize
        color: root.iconColor
        animateText: true
        opacity: root.enabled ? 1 : Tokens.opacity.disabledContent
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
