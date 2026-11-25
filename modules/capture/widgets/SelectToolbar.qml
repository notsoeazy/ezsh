import QtQuick

import qs
import qs.services
import qs.components

// Picks what to capture (region, window, screen), whether to screenshot or record, and recording sound.
CaptureBar {
    id: root

    readonly property var modes: [
        { name: "region", label: "Region", icon: "screenshot_region" },
        { name: "window", label: "Window", icon: "select_window" },
        { name: "screen", label: "Screen", icon: "fullscreen" }
    ]

    Repeater {
        model: root.modes

        Button {
            id: modeButton

            required property var modelData

            type: "standard"
            buttonHeight: root.buttonHeight
            icon: modeButton.modelData.icon
            text: modeButton.modelData.label
            checked: CaptureService.mode === modeButton.modelData.name
            onClicked: CaptureService.setMode(modeButton.modelData.name)

            ShortcutTip {
                label: "Next mode"
                keys: ["tab"]
            }
        }
    }

    CaptureBar.Separator {}

    Button {
        type: "standard"
        buttonHeight: root.buttonHeight
        icon: "photo_camera"
        checked: CaptureService.kind === "screenshot"
        Accessible.name: "Screenshot"
        onClicked: CaptureService.setKind("screenshot")

        ShortcutTip {
            label: "Screenshot"
        }
    }

    Button {
        type: "standard"
        buttonHeight: root.buttonHeight
        icon: "videocam"
        checked: CaptureService.kind === "record"
        Accessible.name: "Record"
        onClicked: CaptureService.setKind("record")

        ShortcutTip {
            label: "Record"
        }
    }

    Reveal {
        anchors.verticalCenter: parent.verticalCenter
        revealed: CaptureService.kind === "record"
        leadingGap: Tokens.spacing.xxs

        Button {
            type: "standard"
            buttonHeight: root.buttonHeight
            icon: CaptureService.recordAudio ? "volume_up" : "volume_off"
            checked: CaptureService.recordAudio
            Accessible.name: "Record sound"
            onClicked: CaptureService.setRecordAudio(!CaptureService.recordAudio)

            ShortcutTip {
                label: CaptureService.recordAudio ? "Sound on" : "Sound off"
            }
        }
    }

    CaptureBar.Separator {}

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
