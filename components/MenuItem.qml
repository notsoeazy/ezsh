import QtQuick

import qs
import qs.themes

Item {
    id: root

    property string icon: ""
    property string text: ""
    property bool selected: false
    // Compact rows for long menus (tray app menus).
    property bool dense: false
    // A chevron for an entry that opens a submenu.
    property string trailingIcon: ""

    readonly property int itemHeight: 44
    readonly property int denseItemHeight: 32

    signal clicked()

    width: parent?.width ?? implicitWidth
    implicitWidth: content.implicitWidth + Tokens.spacing.md * 2 + (trailing.visible ? trailing.width + Tokens.spacing.sm : 0)
    implicitHeight: root.dense ? root.denseItemHeight : root.itemHeight
    opacity: root.enabled ? 1 : Tokens.opacity.disabledContent
    activeFocusOnTab: root.enabled

    Accessible.role: Accessible.MenuItem
    Accessible.name: root.text
    Accessible.checked: root.selected
    Accessible.onPressAction: root.clicked()

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.clicked();
            event.accepted = true;
        }
    }

    StyledRectangle {
        anchors.fill: parent
        radius: root.dense ? Tokens.radius.md : Tokens.radius.lg
        color: root.selected ? Theme.color.m3tertiaryContainer : Qt.alpha(Theme.color.m3tertiaryContainer, 0)
        border.width: root.activeFocus ? Tokens.stroke.thick : 0
        border.color: Theme.color.m3secondary

        StateLayer {
            hovered: mouseArea.containsMouse
            pressed: mouseArea.pressed
        }
    }

    Row {
        id: content

        x: Tokens.spacing.md
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.sm

        StyledIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            text: root.icon
            iconSize: root.dense ? Tokens.icon.sm : Tokens.icon.md
            fillAmount: root.selected ? 1 : 0
            color: root.selected ? Theme.color.m3onTertiaryContainer : Theme.color.m3onSurface
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            animateFontSize: false
            text: root.text
            font.pixelSize: Tokens.fontSize.sm
            color: root.selected ? Theme.color.m3onTertiaryContainer : Theme.color.m3onSurface
        }
    }

    StyledIcon {
        id: trailing

        anchors.right: parent.right
        anchors.rightMargin: Tokens.spacing.sm
        anchors.verticalCenter: parent.verticalCenter
        visible: root.trailingIcon !== ""
        text: root.trailingIcon
        iconSize: root.dense ? Tokens.icon.sm : Tokens.icon.md
        color: Theme.color.m3onSurfaceVariant
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
