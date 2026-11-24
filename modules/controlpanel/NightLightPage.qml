import QtQuick

import qs
import qs.themes
import qs.services
import qs.components

// Turns the night light on and off and sets how warm it is.
PanelPage {
    id: root

    readonly property int kelvinWidth: 64
    readonly property int kelvinRange: NightLightService.coolest - NightLightService.warmest

    title: "Night Light"
    accessory: Switch {
        checked: NightLightService.enabled
        Accessible.name: "Night light"
        onToggled: NightLightService.toggle()
    }

    Item {
        width: parent.width
        height: Tokens.controlPanel.controlHeight

        StyledIcon {
            id: warmIcon

            x: Tokens.spacing.xs
            anchors.verticalCenter: parent.verticalCenter
            text: "local_fire_department"
            iconSize: Tokens.icon.lg
            color: Theme.color.m3onSurfaceVariant
        }

        Slider {
            anchors {
                left: warmIcon.right
                right: coolIcon.left
                leftMargin: Tokens.spacing.sm
                rightMargin: Tokens.spacing.sm
                verticalCenter: parent.verticalCenter
            }

            value: (NightLightService.temperature - NightLightService.warmest) / root.kelvinRange
            Accessible.name: "Night light temperature"
            onValueRequested: value => NightLightService.setTemperature(NightLightService.warmest + value * root.kelvinRange)
            onStepRequested: direction => NightLightService.stepTemperature(direction)
        }

        StyledIcon {
            id: coolIcon

            anchors.right: kelvin.left
            anchors.verticalCenter: parent.verticalCenter
            text: "ac_unit"
            iconSize: Tokens.icon.lg
            color: Theme.color.m3onSurfaceVariant
        }

        StyledText {
            id: kelvin

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: root.kelvinWidth
            horizontalAlignment: Text.AlignRight
            animateFontSize: false
            text: `${NightLightService.temperature} K`
            font.pixelSize: Tokens.fontSize.sm
            color: Theme.color.m3onSurface
        }
    }

    StyledText {
        width: parent.width
        wrapText: true
        animateFontSize: false
        text: "Warmer colours are easier on the eyes at night."
        font.pixelSize: Tokens.fontSize.xs
        color: Theme.color.m3onSurfaceVariant
    }
}
