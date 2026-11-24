import QtQuick

import qs
import qs.themes
import qs.services
import qs.components

// The power mode and (on Lenovo IdeaPad) conservation mode.
PanelPage {
    id: root

    readonly property int modeButtonHeight: 44
    readonly property int rowHeight: 64

    title: "Battery"

    // sysfs sends no change events; read the current value whenever the page is shown.
    onShownChanged: {
        if (root.shown)
            PowerService.refreshConservation();
    }

    SectionHeader {
        text: "Power profile"
    }

    // A connected button group (M3): pill outer ends, small inner corners; the chosen one turns fully round.
    Row {
        id: modes

        readonly property real buttonWidth: (width - spacing * (PowerService.profiles.length - 1)) / PowerService.profiles.length
        readonly property real pill: root.modeButtonHeight / 2

        width: parent.width
        spacing: Tokens.spacing.xxs

        Repeater {
            model: PowerService.profiles

            Button {
                required property var modelData
                required property int index

                readonly property bool chosen: modelData.value === PowerService.profile

                width: modes.buttonWidth
                buttonHeight: root.modeButtonHeight
                icon: modelData.icon
                text: modelData.label
                checked: chosen
                startRadius: chosen || index === 0 ? modes.pill : Tokens.radius.sm
                endRadius: chosen || index === PowerService.profiles.length - 1 ? modes.pill : Tokens.radius.sm
                onClicked: PowerService.setProfile(modelData.value)
            }
        }
    }

    SectionHeader {
        visible: PowerService.conservationAvailable
        text: "Battery Limit"
    }

    Item {
        id: conservation

        width: parent.width
        height: root.rowHeight
        visible: PowerService.conservationAvailable

        Accessible.role: Accessible.CheckBox
        Accessible.name: "Conservation mode"
        Accessible.checked: PowerService.conservationMode

        StyledRectangle {
            anchors.fill: parent
            radius: Tokens.radius.xl
            color: Theme.color.m3surfaceContainerHigh

            StateLayer {
                hovered: conservationArea.containsMouse && PowerService.conservationWritable
                pressed: conservationArea.pressed && PowerService.conservationWritable
            }
        }

        MouseArea {
            id: conservationArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: PowerService.conservationWritable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: PowerService.setConservationMode(!PowerService.conservationMode)
        }

        StyledIcon {
            id: conservationIcon

            x: Tokens.spacing.md
            anchors.verticalCenter: parent.verticalCenter
            text: "battery_saver"
            iconSize: Tokens.icon.lg
            color: Theme.color.m3onSurfaceVariant
        }

        Column {
            anchors {
                left: conservationIcon.right
                right: conservationSwitch.left
                leftMargin: Tokens.spacing.md
                rightMargin: Tokens.spacing.md
                verticalCenter: parent.verticalCenter
            }

            StyledText {
                width: parent.width
                elideText: true
                animateFontSize: false
                text: "Conservation mode"
                font.pixelSize: Tokens.fontSize.sm
                color: Theme.color.m3onSurface
            }

            StyledText {
                width: parent.width
                elideText: true
                animateFontSize: false
                text: PowerService.conservationWritable ? "Stops charging early to extend battery life" : "Needs write access: see scripts/99-ezsh-conservation-mode.rules"
                font.pixelSize: Tokens.fontSize.xs
                color: PowerService.conservationWritable ? Theme.color.m3onSurfaceVariant : Theme.color.m3error
            }
        }

        Switch {
            id: conservationSwitch

            anchors.right: parent.right
            anchors.rightMargin: Tokens.spacing.md
            anchors.verticalCenter: parent.verticalCenter
            checked: PowerService.conservationMode
            enabled: PowerService.conservationWritable
            Accessible.name: "Conservation mode"
            onToggled: PowerService.setConservationMode(!PowerService.conservationMode)
        }
    }
}
