import QtQuick

import qs
import qs.themes

Item {
    id: root

    property string icon: ""
    property string headline: ""
    property string supportingText: ""
    property string trailingIcon: ""
    property bool selected: false
    property bool first: false
    property bool last: false
    // False for a row that only shows state: no hover, cursor, focus or clicks.
    property bool interactive: true
    // Show a RadioButton in place of trailingIcon (a pick-one list); the whole row selects.
    property bool radio: false
    property bool checked: false

    readonly property int defaultHeight: 56
    readonly property real topRadius: root.first || root.selected ? Tokens.radius.xl : Tokens.radius.sm
    readonly property real bottomRadius: root.last || root.selected ? Tokens.radius.xl : Tokens.radius.sm

    signal clicked()

    implicitHeight: root.defaultHeight
    activeFocusOnTab: root.interactive

    Accessible.role: !root.interactive ? Accessible.StaticText : root.radio ? Accessible.RadioButton : Accessible.Button
    Accessible.checked: root.checked
    Accessible.name: root.headline
    Accessible.description: root.supportingText
    Accessible.onPressAction: root.clicked()

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.clicked();
            event.accepted = true;
        }
    }

    StyledRectangle {
        anchors.fill: parent
        color: root.selected ? Theme.color.m3secondaryContainer : Theme.color.m3surfaceContainerHigh
        topLeftRadius: root.topRadius
        topRightRadius: root.topRadius
        bottomLeftRadius: root.bottomRadius
        bottomRightRadius: root.bottomRadius
        border.width: root.activeFocus ? Tokens.stroke.thick : 0
        border.color: Theme.color.m3secondary

        StateLayer {
            hovered: mouseArea.containsMouse
            pressed: mouseArea.pressed
        }
    }

    StyledIcon {
        id: leading

        x: Tokens.spacing.md
        anchors.verticalCenter: parent.verticalCenter
        visible: root.icon !== ""
        text: root.icon
        iconSize: Tokens.icon.lg
        color: root.selected ? Theme.color.m3onSecondaryContainer : Theme.color.m3onSurfaceVariant
    }

    Column {
        anchors {
            left: root.icon !== "" ? leading.right : parent.left
            right: radioButton.visible ? radioButton.left : trailing.visible ? trailing.left : parent.right
            leftMargin: Tokens.spacing.md
            rightMargin: Tokens.spacing.md
            verticalCenter: parent.verticalCenter
        }

        StyledText {
            width: parent.width
            elideText: true
            animateFontSize: false
            text: root.headline
            font.pixelSize: Tokens.fontSize.sm
            color: root.selected ? Theme.color.m3onSecondaryContainer : Theme.color.m3onSurface
        }

        StyledText {
            width: parent.width
            visible: root.supportingText !== ""
            elideText: true
            animateFontSize: false
            text: root.supportingText
            font.pixelSize: Tokens.fontSize.xs
            color: Theme.color.m3onSurfaceVariant
        }
    }

    StyledIcon {
        id: trailing

        anchors {
            right: parent.right
            rightMargin: Tokens.spacing.md
            verticalCenter: parent.verticalCenter
        }

        visible: !root.radio && root.trailingIcon !== ""
        text: root.trailingIcon
        iconSize: Tokens.icon.md
        color: root.selected ? Theme.color.m3onSecondaryContainer : Theme.color.m3onSurfaceVariant
    }

    RadioButton {
        id: radioButton

        anchors {
            right: parent.right
            rightMargin: Tokens.spacing.xs
            verticalCenter: parent.verticalCenter
        }

        visible: root.radio
        checked: root.checked
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
