import QtQuick

import qs
import qs.themes
import qs.services
import qs.components

// Power profile and battery charge limit.
PanelPage {
    id: root

    readonly property int modeButtonHeight: 44
    readonly property int rowHeight: 64

    title: "Battery"

    // Changes made outside ezsh show up the next time the page opens.
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
                id: modeButton

                required property var modelData
                required property int index

                readonly property bool chosen: modeButton.modelData.value === PowerService.profile

                width: modes.buttonWidth
                buttonHeight: root.modeButtonHeight
                icon: modeButton.modelData.icon
                text: modeButton.modelData.label
                checked: modeButton.chosen
                startRadius: modeButton.chosen || modeButton.index === 0 ? modes.pill : Tokens.radius.sm
                endRadius: modeButton.chosen || modeButton.index === PowerService.profiles.length - 1 ? modes.pill : Tokens.radius.sm
                onClicked: PowerService.setProfile(modeButton.modelData.value)
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
        Accessible.name: "Battery charge limit"
        Accessible.checked: PowerService.conservationMode

        StyledRectangle {
            anchors.fill: parent
            radius: Tokens.radius.xl
            color: Theme.color.m3surfaceContainerHigh

            StateLayer {
                hovered: conservationArea.containsMouse && !PowerService.conservationBusy
                pressed: conservationArea.pressed && !PowerService.conservationBusy
            }
        }

        MouseArea {
            id: conservationArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: PowerService.conservationBusy ? Qt.ArrowCursor : Qt.PointingHandCursor
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
                text: "Battery charge limit"
                font.pixelSize: Tokens.fontSize.sm
                color: Theme.color.m3onSurface
            }

            StyledText {
                width: parent.width
                elideText: true
                animateFontSize: false
                text: PowerService.conservationError ? "Could not change charge limit" : "Stops charging early to extend battery life"
                font.pixelSize: Tokens.fontSize.xs
                color: PowerService.conservationError ? Theme.color.m3error : Theme.color.m3onSurfaceVariant
            }
        }

        Switch {
            id: conservationSwitch

            anchors.right: parent.right
            anchors.rightMargin: Tokens.spacing.md
            anchors.verticalCenter: parent.verticalCenter
            checked: PowerService.conservationMode
            enabled: !PowerService.conservationBusy
            Accessible.name: "Battery charge limit"
            onToggled: PowerService.setConservationMode(!PowerService.conservationMode)
        }
    }
}
