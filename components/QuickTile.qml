import QtQuick

import qs
import qs.themes

Item {
    id: root

    property string title: ""
    property string status: ""
    property string icon: ""
    property bool checked: false
    property bool hasPage: false

    readonly property int tileHeight: 60
    readonly property int tileWidth: 192
    readonly property int chevronSize: 28
    readonly property real iconCircleSize: root.height - Tokens.spacing.xs * 2

    signal toggled()
    signal opened()

    implicitWidth: root.tileWidth
    implicitHeight: root.tileHeight
    opacity: root.enabled ? 1 : Tokens.opacity.disabledContent
    activeFocusOnTab: true

    Accessible.role: Accessible.CheckBox
    Accessible.name: root.title
    Accessible.checked: root.checked
    Accessible.onPressAction: root.toggled()
    Accessible.onToggleAction: root.toggled()

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.toggled();
            event.accepted = true;
        }
    }

    StyledRectangle {
        anchors.fill: parent
        radius: Tokens.radius.xl
        color: Theme.color.m3surfaceContainerHigh
        border.width: root.activeFocus ? Tokens.stroke.thick : 0
        border.color: Theme.color.m3secondary

        StateLayer {
            hovered: body.containsMouse
            pressed: body.pressed
        }
    }

    MouseArea {
        id: body

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }

    StyledRectangle {
        id: iconCircle

        x: Tokens.spacing.xs
        anchors.verticalCenter: parent.verticalCenter
        width: root.iconCircleSize
        height: root.iconCircleSize
        radius: Tokens.radius.full
        color: root.checked ? Theme.color.m3primary : Qt.alpha(Theme.color.m3primary, 0)

        StyledIcon {
            anchors.centerIn: parent
            text: root.icon
            iconSize: Tokens.icon.lg
            fillAmount: root.checked ? 1 : 0
            animateTextChange: true
            color: root.checked ? Theme.color.m3onPrimary : Theme.color.m3onSurface
        }
    }

    Column {
        anchors {
            left: iconCircle.right
            right: root.hasPage ? chevron.left : parent.right
            leftMargin: Tokens.spacing.sm
            rightMargin: Tokens.spacing.xs
            verticalCenter: parent.verticalCenter
        }

        StyledText {
            width: parent.width
            elideText: true
            animateFontSize: false
            text: root.title
            font.pixelSize: Tokens.fontSize.sm
            font.weight: Tokens.font.semibold
            color: Theme.color.m3onSurface
        }

        StyledText {
            width: parent.width
            visible: root.status !== ""
            elideText: true
            animateFontSize: false
            text: root.status
            font.pixelSize: Tokens.fontSize.xs
            color: Theme.color.m3onSurfaceVariant
        }
    }

    Button {
        id: chevron

        anchors.right: parent.right
        anchors.rightMargin: Tokens.spacing.sm
        anchors.verticalCenter: parent.verticalCenter
        visible: root.hasPage
        buttonHeight: root.chevronSize
        icon: "chevron_right"
        containerColor: Theme.color.m3surfaceContainerHighest
        contentColor: Theme.color.m3onSurfaceVariant
        Accessible.name: root.title + " details"
        onClicked: root.opened()
    }
}
