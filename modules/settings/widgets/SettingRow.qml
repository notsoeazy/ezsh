import QtQuick

import qs
import qs.config
import qs.themes
import qs.components

// One setting, drawn from its row object:
//   { type, label, description and icon (text, or a function returning it; icon leads the row), and
//     either key: "group.name" (a Config value) or get() / set(value) }
//   "switch"                                     a Switch
//   "number": min, max, step, unit, scale        a Stepper (type or step); shown divided by scale (ms as s)
//   "slider": min, max, step, unit               a thin Slider and its value, for a range with real ends
//   "choice": options: [{ label, value }]        connected buttons
//   "text":   placeholder, toText(value), fromText(text) (undefined rejects), allowEmpty,
//             secret (a password), focused (takes the keyboard when it appears)
//   "action": button, run() or buttons: [{ text, run, enabled() }]
//   "radio":  get() = chosen, run()               a pick-one row; the whole row picks it
//   "info":   get() = the text shown on the right
// Labels stay beside the control while both fit, and the control moves under them when not.
Item {
    id: root

    required property var setting

    readonly property int horizontalPadding: Tokens.spacing.lg
    readonly property int verticalPadding: Tokens.spacing.md
    readonly property int minRowHeight: 64
    readonly property int minLabelWidth: 180
    readonly property int valueWidth: 72

    readonly property string type: root.setting.type ?? ""
    readonly property var keyPath: (root.setting.key ?? "").split(".")
    readonly property var value: root.setting.get ? root.setting.get() : Config[root.keyPath[0]]?.[root.keyPath[1]]
    readonly property string descriptionText: root.textOf(root.setting.description)
    readonly property string iconName: root.textOf(root.setting.icon)
    readonly property real labelsX: root.iconName !== "" ? root.horizontalPadding + Tokens.icon.lg + Tokens.spacing.md : root.horizontalPadding
    readonly property bool stretches: root.type === "slider" || root.type === "text"
    readonly property real innerWidth: Math.max(0, root.width - root.horizontalPadding * 2)
    readonly property bool stacked: control.implicitWidth + Tokens.spacing.md + root.minLabelWidth + root.labelsX - root.horizontalPadding > root.innerWidth
    readonly property real labelsHeight: labelText.implicitHeight + (descriptionLabel.visible ? descriptionLabel.implicitHeight : 0)

    implicitHeight: root.stacked
        ? root.labelsHeight + Tokens.spacing.sm + control.implicitHeight + root.verticalPadding * 2
        : Math.max(root.minRowHeight, root.labelsHeight + root.verticalPadding * 2, control.implicitHeight + root.verticalPadding * 2)

    function textOf(value) {
        return typeof value === "function" ? value() : value ?? "";
    }

    function write(value) {
        if (value === undefined)
            return;
        if (root.setting.set) {
            root.setting.set(value);
            return;
        }
        const group = Config[root.keyPath[0]];
        if (!group || !(root.keyPath[1] in group)) {
            console.warn("SettingRow: no Config key", root.setting.key);
            return;
        }
        group[root.keyPath[1]] = value;
    }

    // Snaps to the step from min and clamps to the range.
    function snapped(value) {
        const step = root.setting.step || 1;
        const snapped = root.setting.min + Math.round((value - root.setting.min) / step) * step;
        return Math.max(root.setting.min, Math.min(root.setting.max, snapped));
    }

    function numberText(value) {
        const scale = root.setting.scale || 1;
        const decimals = scale > 1 ? 1 : 0;
        const shown = Number((value / scale).toFixed(decimals));
        return root.setting.unit ? `${shown} ${root.setting.unit}` : `${shown}`;
    }

    // A switch or radio row answers a click anywhere on it; this lies under the labels and the control.
    MouseArea {
        anchors.fill: parent
        enabled: root.type === "switch" || root.type === "radio"
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.type === "radio")
                root.setting.run?.();
            else
                root.write(!root.value);
        }
    }

    StyledIcon {
        x: root.horizontalPadding
        y: labels.y + (root.labelsHeight - height) / 2
        visible: root.iconName !== ""
        text: root.iconName
        iconSize: Tokens.icon.lg
        color: Theme.color.m3onSurfaceVariant
    }

    // Label and description, placed by hand: a Column here measured mid-binding loops at creation.
    Item {
        id: labels

        x: root.labelsX
        y: root.stacked ? root.verticalPadding : (root.height - root.labelsHeight) / 2
        width: Math.max(0, root.width - root.horizontalPadding - root.labelsX - (root.stacked ? 0 : control.width + Tokens.spacing.md))
        height: root.labelsHeight

        StyledText {
            id: labelText

            width: parent.width
            elideText: true
            animateFontSize: false
            text: root.setting.label ?? ""
            font.pixelSize: Tokens.fontSize.md
            color: Theme.color.m3onSurface
        }

        StyledText {
            id: descriptionLabel

            y: labelText.implicitHeight
            width: parent.width
            visible: text !== ""
            wrapText: true
            animateFontSize: false
            text: root.descriptionText
            font.pixelSize: Tokens.fontSize.xs
            color: Theme.color.m3onSurfaceVariant
        }
    }

    Loader {
        id: control

        x: root.stacked ? root.horizontalPadding : root.width - root.horizontalPadding - width
        y: root.stacked ? root.verticalPadding + root.labelsHeight + Tokens.spacing.sm : (root.height - height) / 2
        width: root.stacked && root.stretches ? root.innerWidth : control.implicitWidth
        sourceComponent: root.type === "switch" ? switchControl
            : root.type === "number" ? numberControl
            : root.type === "slider" ? sliderControl
            : root.type === "choice" ? choiceControl
            : root.type === "text" ? textControl
            : root.type === "action" ? actionControl
            : root.type === "radio" ? radioControl
            : root.type === "info" ? infoControl : null
    }

    Component {
        id: switchControl

        Switch {
            checked: !!root.value
            Accessible.name: root.setting.label
            onToggled: root.write(!root.value)
        }
    }

    Component {
        id: numberControl

        Stepper {
            readonly property real scale: root.setting.scale || 1

            value: (root.value ?? root.setting.min) / scale
            from: root.setting.min / scale
            to: root.setting.max / scale
            stepSize: (root.setting.step || 1) / scale
            decimals: scale > 1 ? 1 : 0
            unit: root.setting.unit ?? ""
            Accessible.name: root.setting.label
            onValueRequested: value => root.write(Math.round(value * scale))
        }
    }

    Component {
        id: sliderControl

        Item {
            id: number

            readonly property real range: Math.max(1, root.setting.max - root.setting.min)

            implicitWidth: slider.implicitWidth + Tokens.spacing.sm + root.valueWidth
            implicitHeight: slider.implicitHeight

            Slider {
                id: slider

                width: number.width - Tokens.spacing.sm - root.valueWidth
                thin: true
                value: ((root.value ?? root.setting.min) - root.setting.min) / number.range
                Accessible.name: root.setting.label
                Accessible.description: root.numberText(root.value)
                onValueRequested: value => root.write(root.snapped(root.setting.min + value * number.range))
                onStepRequested: direction => root.write(root.snapped(root.value + direction * (root.setting.step || 1)))
            }

            StyledText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: root.valueWidth
                horizontalAlignment: Text.AlignRight
                animateFontSize: false
                text: root.numberText(root.value)
                font.pixelSize: Tokens.fontSize.sm
                font.features: ({
                    "tnum": 1
                })
                color: Theme.color.m3onSurface
            }
        }
    }

    Component {
        id: choiceControl

        Row {
            id: choices

            readonly property var options: root.setting.options ?? []
            readonly property real pill: Tokens.controlPanel.controlHeight / 2

            spacing: Tokens.spacing.xxs

            Repeater {
                model: choices.options

                Button {
                    id: choiceButton

                    required property var modelData
                    required property int index

                    readonly property bool chosen: choiceButton.modelData.value === root.value

                    buttonHeight: Tokens.controlPanel.controlHeight
                    text: choiceButton.modelData.label
                    checked: choiceButton.chosen
                    startRadius: choiceButton.chosen || choiceButton.index === 0 ? choices.pill : Tokens.radius.sm
                    endRadius: choiceButton.chosen || choiceButton.index === choices.options.length - 1 ? choices.pill : Tokens.radius.sm
                    onClicked: root.write(choiceButton.modelData.value)
                }
            }
        }
    }

    Component {
        id: textControl

        TextField {
            text: root.setting.toText ? root.setting.toText(root.value) : `${root.value ?? ""}`
            placeholder: root.setting.placeholder ?? ""
            echoMode: root.setting.secret ? TextInput.Password : TextInput.Normal
            startFocused: !!root.setting.focused
            Accessible.name: root.setting.label
            onSubmitted: text => {
                if (root.setting.fromText)
                    root.write(root.setting.fromText(text));
                else if (text.trim() !== "" || root.setting.allowEmpty)
                    root.write(text.trim());
            }
        }
    }

    Component {
        id: actionControl

        Row {
            id: actions

            spacing: Tokens.spacing.xs

            Repeater {
                model: root.setting.buttons ?? [{ text: root.setting.button, run: root.setting.run }]

                Button {
                    id: actionButton

                    required property var modelData

                    text: actionButton.modelData.text ?? ""
                    enabled: actionButton.modelData.enabled?.() ?? true
                    Accessible.name: `${actionButton.modelData.text}: ${root.setting.label}`
                    onClicked: actionButton.modelData.run?.()
                }
            }
        }
    }

    Component {
        id: radioControl

        RadioButton {
            checked: !!root.value
        }
    }

    Component {
        id: infoControl

        StyledText {
            animateFontSize: false
            text: `${root.value ?? ""}`
            font.pixelSize: Tokens.fontSize.sm
            color: Theme.color.m3onSurfaceVariant
        }
    }
}
