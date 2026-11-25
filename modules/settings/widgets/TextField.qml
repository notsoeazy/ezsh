import QtQuick

import qs
import qs.themes
import qs.components

// A one-line text box that reports its text once, on Enter or when it loses focus (a password: Enter only); Esc restores
// `text`. It shows `text` again afterwards, so the owner's value wins (a rejected entry reverts).
FocusScope {
    id: root

    property string text: ""
    property string placeholder: ""
    property int echoMode: TextInput.Normal
    // Takes the keyboard once created (a field that appears after a click, like a password).
    property bool startFocused: false
    // Leaving the field submits too, except for a password: half-typed, it would be used.
    readonly property bool submitOnBlur: root.echoMode === TextInput.Normal

    readonly property int fieldHeight: 40
    readonly property int defaultWidth: 260

    signal submitted(string text)

    implicitWidth: root.defaultWidth
    implicitHeight: root.fieldHeight
    activeFocusOnTab: true

    Accessible.role: Accessible.EditableText
    Accessible.name: root.placeholder

    function submit() {
        if (input.text !== root.text)
            root.submitted(input.text);
        input.text = root.text;
    }

    Component.onCompleted: {
        if (root.startFocused)
            input.forceActiveFocus();
    }

    onTextChanged: {
        if (!input.activeFocus)
            input.text = root.text;
    }

    StyledRectangle {
        anchors.fill: parent
        radius: Tokens.radius.full
        color: Theme.color.m3surfaceContainerHigh
        border.width: input.activeFocus ? Tokens.stroke.thick : 0
        border.color: Theme.color.m3primary
    }

    TextInput {
        id: input

        anchors {
            left: parent.left
            right: parent.right
            leftMargin: Tokens.spacing.md
            rightMargin: Tokens.spacing.md
            verticalCenter: parent.verticalCenter
        }

        focus: true
        clip: true
        text: root.text
        echoMode: root.echoMode
        color: Theme.color.m3onSurface
        selectionColor: Theme.color.m3primaryContainer
        selectedTextColor: Theme.color.m3onPrimaryContainer
        selectByMouse: true
        font.family: Tokens.font.family
        font.pixelSize: Tokens.fontSize.sm
        font.weight: Tokens.font.regular

        onAccepted: root.submit()
        onActiveFocusChanged: {
            if (!input.activeFocus && root.submitOnBlur)
                root.submit();
        }

        Keys.onEscapePressed: event => {
            input.text = root.text;
            event.accepted = true;
        }

        StyledText {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            visible: input.text === ""
            elideText: true
            animateFontSize: false
            text: root.placeholder
            font: input.font
            color: Theme.color.m3outline
        }
    }
}
