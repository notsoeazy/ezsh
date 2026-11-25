import QtQuick

import qs
import qs.themes
import qs.components

// A sidebar entry: an icon in a circle and the page title; compact shows only the circle.
Item {
    id: root

    property string icon: ""
    property string text: ""
    property bool selected: false
    property bool compact: false

    readonly property int itemHeight: 56
    readonly property int circleSize: 40
    readonly property int inset: (root.itemHeight - root.circleSize) / 2

    signal clicked()

    implicitWidth: root.compact ? root.itemHeight : root.inset * 2 + root.circleSize + Tokens.spacing.md + label.implicitWidth
    implicitHeight: root.itemHeight
    activeFocusOnTab: true

    Accessible.role: Accessible.PageTab
    Accessible.name: root.text
    Accessible.selected: root.selected
    Accessible.onPressAction: root.clicked()

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.clicked();
            event.accepted = true;
        }
    }

    StyledRectangle {
        anchors.fill: parent
        radius: Tokens.radius.full
        color: root.selected ? Theme.color.m3surfaceContainerHigh : Qt.alpha(Theme.color.m3surfaceContainerHigh, 0)
        border.width: root.activeFocus ? Tokens.stroke.thick : 0
        border.color: Theme.color.m3secondary

        StateLayer {
            hovered: mouseArea.containsMouse
            pressed: mouseArea.pressed
        }
    }

    StyledRectangle {
        id: circle

        x: root.inset
        anchors.verticalCenter: parent.verticalCenter
        width: root.circleSize
        height: root.circleSize
        radius: Tokens.radius.full
        color: root.selected ? Theme.color.m3primary : Theme.color.m3surfaceContainerHigh

        StyledIcon {
            anchors.centerIn: parent
            text: root.icon
            iconSize: Tokens.icon.md
            fillAmount: root.selected ? 1 : 0
            color: root.selected ? Theme.color.m3onPrimary : Theme.color.m3primary
        }
    }

    StyledText {
        id: label

        anchors {
            left: circle.right
            right: parent.right
            leftMargin: Tokens.spacing.md
            rightMargin: root.inset
            verticalCenter: parent.verticalCenter
        }

        opacity: root.compact ? 0 : 1
        visible: opacity > 0
        elideText: true
        animateFontSize: false
        text: root.text
        font.pixelSize: Tokens.fontSize.md
        color: Theme.color.m3onSurface

        Behavior on opacity {
            Anim {
                duration: Tokens.animDuration.effectsFast
            }
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
