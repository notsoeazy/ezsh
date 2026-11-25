import QtQuick

import qs
import qs.themes

FocusScope {
    id: root

    property alias text: input.text
    property alias echoMode: input.echoMode
    property string placeholder: "Search"
    property string icon: "search"

    readonly property int barHeight: 48
    readonly property int clearButtonSize: 32

    signal accepted()
    signal moveRequested(int direction) // -1 up, +1 down
    signal escapePressed()
    signal backspaceOnEmpty()

    implicitHeight: root.barHeight
    Accessible.role: Accessible.EditableText
    Accessible.name: root.placeholder

    function selectAll() {
        input.selectAll();
    }

    StyledRectangle {
        anchors.fill: parent
        radius: Tokens.radius.full
        color: Theme.color.m3surfaceContainerHigh
    }

    StyledIcon {
        id: leadingIcon

        x: Tokens.spacing.md
        anchors.verticalCenter: parent.verticalCenter
        iconSize: Tokens.icon.lg
        animateTextChange: true
        text: root.icon
        color: Theme.color.m3onSurface
    }

    TextInput {
        id: input

        anchors {
            left: leadingIcon.right
            right: clearButton.left
            leftMargin: Tokens.spacing.sm
            rightMargin: Tokens.spacing.xxs
            verticalCenter: parent.verticalCenter
        }

        focus: true
        clip: true
        color: Theme.color.m3onSurface
        selectionColor: Theme.color.m3primaryContainer
        selectedTextColor: Theme.color.m3onPrimaryContainer
        selectByMouse: true
        font.family: Tokens.font.family
        font.pixelSize: Tokens.fontSize.md
        font.weight: Tokens.font.regular

        onAccepted: root.accepted()

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                root.moveRequested(event.key === Qt.Key_Up ? -1 : 1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                root.escapePressed();
                event.accepted = true;
            } else if (event.key === Qt.Key_Backspace && input.text === "") {
                root.backspaceOnEmpty();
                event.accepted = true;
            }
        }

        StyledText {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            elideText: true
            animateFontSize: false
            text: root.placeholder
            font: input.font
            color: Theme.color.m3onSurfaceVariant
        }
    }

    Reveal {
        id: clearButton

        anchors.right: parent.right
        anchors.rightMargin: Tokens.spacing.md - (root.clearButtonSize - Tokens.icon.lg) / 2
        anchors.verticalCenter: parent.verticalCenter
        revealed: input.text !== ""

        Button {
            type: "standard"
            buttonHeight: root.clearButtonSize
            iconSize: Tokens.icon.lg
            icon: "close"
            contentColor: Theme.color.m3onSurfaceVariant
            activeFocusOnTab: false
            Accessible.name: "Clear search"
            onClicked: {
                input.text = "";
                input.forceActiveFocus();
            }
        }
    }
}
