import QtQuick
import qs
import qs.themes

Item {
    id: root

    required property string icon
    property bool filled: false
    property real buttonSize: 32
    property int iconSize: Tokens.icon.md
    property color iconColor: Theme.color.m3onSurface

    signal clicked()

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    activeFocusOnTab: true

    Accessible.role: Accessible.Button
    Accessible.name: root.icon
    Accessible.onPressAction: root.clicked()

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.clicked();
            event.accepted = true;
        }
    }

    StyledRectangle {
        anchors.fill: parent
        color: Theme.color.m3onSurface
        radius: mouseArea.pressed ? Tokens.radius.md : root.buttonSize / 2
        opacity: !root.enabled ? 0 : mouseArea.pressed ? Tokens.opacity.pressed : mouseArea.containsMouse ? Tokens.opacity.hover : 0

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
        fillAmount: root.filled ? 1 : 0
        iconSize: root.iconSize
        color: root.iconColor
        animateTextChange: true
        opacity: root.enabled ? 1 : Tokens.opacity.disabledContent
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
