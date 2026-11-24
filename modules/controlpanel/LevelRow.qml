import QtQuick

import qs
import qs.components

// A level slider with a round toggle beside it (night light by brightness, microphone by volume).
Item {
    id: root

    property real value: 0 // 0..1
    property string icon: ""
    property string buttonIcon: ""
    property bool buttonChecked: false
    property bool sliderEnabled: true

    signal valueRequested(real value)
    signal stepRequested(real direction)
    signal buttonClicked()
    signal buttonSecondaryClicked()

    implicitHeight: Tokens.controlPanel.controlHeight

    Slider {
        width: root.width - toggle.width - Tokens.spacing.sm
        height: root.height
        value: root.value
        icon: root.icon
        interactive: root.sliderEnabled
        opacity: root.sliderEnabled ? 1 : Tokens.opacity.disabledContent
        onValueRequested: value => root.valueRequested(value)
        onStepRequested: direction => root.stepRequested(direction)
    }

    Button {
        id: toggle

        anchors.right: parent.right
        buttonHeight: root.height
        icon: root.buttonIcon
        checked: root.buttonChecked
        onClicked: root.buttonClicked()
        onSecondaryClicked: root.buttonSecondaryClicked()
    }
}
