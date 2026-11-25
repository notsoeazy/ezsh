import QtQuick

import qs
import qs.config
import qs.themes
import qs.services
import qs.components

// The annotate stage's controls: adjust, drawing tools, colors, undo, copy, save and cancel.
CaptureBar {
    id: root

    required property var tools
    required property string currentTool
    required property color currentColor
    required property bool canUndo
    required property bool chooserOpen

    readonly property Item chooserAnchor: chooserButton
    readonly property bool usingCustomColor: !Config.capture.annotationColors.some(c => Qt.colorEqual(c, root.currentColor))

    signal adjustRequested()
    signal toolChosen(string tool)
    signal colorChosen(color color)
    signal chooserRequested()
    signal undoRequested()
    signal copyRequested()
    signal saveRequested()

    Button {
        type: "standard"
        buttonHeight: root.buttonHeight
        icon: "crop"
        Accessible.name: "Adjust selection"
        onClicked: root.adjustRequested()

        ShortcutTip {
            label: "Adjust selection"
            keys: ["⌫"]
        }
    }

    CaptureBar.Separator {}

    Repeater {
        model: root.tools

        Button {
            id: toolButton

            required property var modelData

            type: "standard"
            buttonHeight: root.buttonHeight
            icon: toolButton.modelData.icon
            checked: root.currentTool === toolButton.modelData.name
            Accessible.name: toolButton.modelData.label
            onClicked: root.toolChosen(toolButton.modelData.name)

            ShortcutTip {
                label: toolButton.modelData.label
                keys: [toolButton.modelData.keyName]
            }
        }
    }

    CaptureBar.Separator {}

    Repeater {
        model: Config.capture.annotationColors

        Item {
            id: swatch

            required property string modelData

            readonly property bool selected: Qt.colorEqual(root.currentColor, swatch.modelData)

            width: root.buttonHeight
            height: root.buttonHeight

            Accessible.role: Accessible.Button
            Accessible.name: `Color ${swatch.modelData}`
            Accessible.onPressAction: root.colorChosen(swatch.modelData)

            StyledRectangle {
                anchors.centerIn: parent
                width: swatch.selected ? Tokens.icon.md : Tokens.icon.sm
                height: width
                radius: Tokens.radius.full
                color: swatch.modelData
                border.width: Tokens.stroke.thick
                border.color: swatch.selected ? Theme.color.m3onSurface : Theme.color.m3outlineVariant

                Behavior on width {
                    Anim {
                        duration: Tokens.animDuration.spatialFast
                        easing.type: Easing.OutBack
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.colorChosen(swatch.modelData)
            }
        }
    }

    Button {
        id: chooserButton

        type: "standard"
        buttonHeight: root.buttonHeight
        icon: "palette"
        checked: root.usingCustomColor || root.chooserOpen
        Accessible.name: "More colors"
        onClicked: root.chooserRequested()

        ShortcutTip {
            label: "More colors"
        }
    }

    CaptureBar.Separator {}

    Button {
        type: "standard"
        buttonHeight: root.buttonHeight
        icon: "undo"
        enabled: root.canUndo
        Accessible.name: "Undo"
        onClicked: root.undoRequested()

        ShortcutTip {
            label: "Undo"
            keys: ["ctrl", "Z"]
        }
    }

    Button {
        buttonHeight: root.buttonHeight
        icon: "content_copy"
        text: "Copy"
        onClicked: root.copyRequested()

        ShortcutTip {
            label: "Copy to clipboard"
            keys: ["↵"]
        }
    }

    Button {
        type: "filled"
        buttonHeight: root.buttonHeight
        icon: "save"
        text: "Save"
        onClicked: root.saveRequested()

        ShortcutTip {
            label: "Save and copy"
            keys: ["shift", "↵"]
        }
    }

    Button {
        type: "standard"
        buttonHeight: root.buttonHeight
        icon: "close"
        Accessible.name: "Cancel"
        onClicked: CaptureService.cancel()

        ShortcutTip {
            label: "Cancel"
            keys: ["esc"]
        }
    }
}
