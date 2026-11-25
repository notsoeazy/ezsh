import QtQuick

import qs
import qs.themes

Item {
    id: root

    property bool checked: false

    // 0 = off, 1 = on; drives the handle's position and size together.
    property real progress: root.checked ? 1 : 0

    readonly property int trackWidth: 52
    readonly property int trackHeight: 32
    readonly property int handleOff: 16
    readonly property int handleOn: 24
    readonly property int handlePressed: 28

    signal toggled()

    implicitWidth: root.trackWidth
    implicitHeight: root.trackHeight
    opacity: root.enabled ? 1 : Tokens.opacity.disabledContent
    activeFocusOnTab: true

    Accessible.role: Accessible.CheckBox
    Accessible.checked: root.checked
    Accessible.onPressAction: root.toggled()
    Accessible.onToggleAction: root.toggled()

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.toggled();
            event.accepted = true;
        }
    }

    Behavior on progress {
        Anim {
            duration: Tokens.animDuration.spatialFast
            easing.type: Easing.OutBack
        }
    }

    StyledRectangle {
        anchors.fill: parent
        radius: Tokens.radius.full
        color: root.checked ? Theme.color.m3primary : Theme.color.m3surfaceContainerHighest
        border.width: Tokens.stroke.thick
        border.color: Qt.alpha(root.activeFocus ? Theme.color.m3secondary : Theme.color.m3outline, root.activeFocus ? 1 : Math.max(0, Math.min(1, 1 - root.progress)))
    }

    StyledRectangle {
        id: handle

        property real size: mouseArea.pressed ? root.handlePressed : root.handleOff + (root.handleOn - root.handleOff) * root.progress
        readonly property real center: root.trackHeight / 2 + (root.trackWidth - root.trackHeight) * root.progress

        x: handle.center - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: handle.size
        height: handle.size
        radius: Tokens.radius.full
        color: root.checked ? Theme.color.m3onPrimary : Theme.color.m3outline

        Behavior on size {
            Anim {
                duration: Tokens.animDuration.spatialFast
            }
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
