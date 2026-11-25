import QtQuick

import qs
import qs.themes

// A number you can type or step: − and + buttons around an editable value, the wheel and Up / Down
// step it, Enter or leaving the field submits what was typed, Esc puts the value back. Like Slider it
// only shows `value` and emits valueRequested (clamped to from..to); the owner writes it.
FocusScope {
    id: root

    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1
    // Decimal places shown and kept from typing.
    property int decimals: 0
    // Shown after the value ("px", "ms").
    property string unit: ""

    readonly property int controlHeight: Tokens.controlPanel.controlHeight
    readonly property int fieldWidth: 64
    readonly property string valueText: Number(root.value).toFixed(root.decimals)

    signal valueRequested(real value)

    implicitWidth: root.controlHeight * 2 + root.fieldWidth + (unitLabel.visible ? unitLabel.implicitWidth + Tokens.spacing.xxs : 0)
    implicitHeight: root.controlHeight
    opacity: root.enabled ? 1 : Tokens.opacity.disabledContent
    activeFocusOnTab: true

    Accessible.role: Accessible.SpinBox
    Accessible.description: `${root.valueText} ${root.unit}`

    function clamped(value) {
        const rounded = Number(value.toFixed(root.decimals));
        return Math.max(root.from, Math.min(root.to, rounded));
    }

    // One stepSize up (+1) or down (-1).
    function step(direction) {
        const next = root.clamped(root.value + direction * root.stepSize);
        if (next !== root.value)
            root.valueRequested(next);
    }

    function submit() {
        const typed = Number(input.text.replace(",", ".").trim());
        if (input.text.trim() !== "" && isFinite(typed) && root.clamped(typed) !== root.value)
            root.valueRequested(root.clamped(typed));
        input.text = root.valueText;
    }

    onValueTextChanged: {
        if (!input.activeFocus)
            input.text = root.valueText;
    }

    StyledRectangle {
        anchors.fill: parent
        radius: Tokens.radius.full
        color: Theme.color.m3surfaceContainerHigh
        border.width: input.activeFocus ? Tokens.stroke.thick : 0
        border.color: Theme.color.m3primary
    }

    Button {
        id: decrease

        type: "standard"
        buttonHeight: root.controlHeight
        icon: "remove"
        enabled: root.value > root.from
        activeFocusOnTab: false
        Accessible.name: "Decrease"
        onClicked: root.step(-1)
    }

    TextInput {
        id: input

        anchors {
            left: decrease.right
            right: increase.left
            verticalCenter: parent.verticalCenter
        }

        focus: true
        clip: true
        text: root.valueText
        horizontalAlignment: TextInput.AlignHCenter
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        validator: RegularExpressionValidator {
            regularExpression: /-?[0-9]*[.,]?[0-9]*/
        }
        color: Theme.color.m3onSurface
        selectionColor: Theme.color.m3primaryContainer
        selectedTextColor: Theme.color.m3onPrimaryContainer
        selectByMouse: true
        font.family: Tokens.font.family
        font.pixelSize: Tokens.fontSize.sm
        font.weight: Tokens.font.semibold
        font.features: ({
            "tnum": 1
        })

        onAccepted: root.submit()
        onActiveFocusChanged: {
            if (input.activeFocus)
                input.selectAll();
            else
                root.submit();
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                root.submit();
                root.step(event.key === Qt.Key_Up ? 1 : -1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape && input.text !== root.valueText) {
                input.text = root.valueText;
                event.accepted = true;
            }
        }
    }

    StyledText {
        id: unitLabel

        anchors.right: increase.left
        anchors.verticalCenter: parent.verticalCenter
        visible: root.unit !== ""
        animateFontSize: false
        text: root.unit
        font.pixelSize: Tokens.fontSize.xs
        color: Theme.color.m3onSurfaceVariant
    }

    Button {
        id: increase

        anchors.right: parent.right
        type: "standard"
        buttonHeight: root.controlHeight
        icon: "add"
        enabled: root.value < root.to
        activeFocusOnTab: false
        Accessible.name: "Increase"
        onClicked: root.step(1)
    }

    // Wheel only; clicks reach the buttons and the field underneath.
    WheelArea {
        anchors.fill: parent
        onStepped: direction => root.step(direction)
    }
}
