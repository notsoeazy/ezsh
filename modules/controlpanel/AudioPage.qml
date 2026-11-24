import QtQuick

import qs
import qs.themes
import qs.services
import qs.components

PanelPage {
    id: root

    title: "Sound"

    PanelList {
        width: parent.width
        radios: true
        sections: [
            { title: "Output", values: AudioService.outputDevices },
            { title: "Input", values: AudioService.inputDevices }
        ]
        headline: node => AudioService.deviceName(node)
        leadingIcon: node => AudioService.deviceIcon(node)
        isChecked: node => node === AudioService.outputNode || node === AudioService.inputNode
        onActivated: node => node.isSink ? AudioService.setOutputDevice(node) : AudioService.setInputDevice(node)
    }

    StyledText {
        width: parent.width
        visible: AudioService.outputDevices.length === 0 && AudioService.inputDevices.length === 0
        wrapText: true
        animateFontSize: false
        text: "No audio devices."
        font.pixelSize: Tokens.fontSize.sm
        color: Theme.color.m3onSurfaceVariant
    }

    SectionHeader {
        text: "Volume Control"
    }

    LevelRow {
        width: parent.width
        sliderEnabled: AudioService.outputReady
        icon: AudioService.volumeIcon
        value: AudioService.outputMuted ? 0 : AudioService.volume
        buttonIcon: AudioService.outputMuted ? "volume_off" : "volume_up"
        buttonChecked: AudioService.outputReady && !AudioService.outputMuted
        Accessible.name: "Volume"
        onValueRequested: value => AudioService.setVolume(value)
        onStepRequested: direction => AudioService.stepVolume(direction)
        onButtonClicked: AudioService.toggleOutputMute()
    }

    LevelRow {
        width: parent.width
        sliderEnabled: AudioService.inputReady
        icon: "mic"
        value: AudioService.micMuted ? 0 : AudioService.micVolume
        buttonIcon: AudioService.micIcon
        buttonChecked: AudioService.inputReady && !AudioService.micMuted
        Accessible.name: "Microphone"
        onValueRequested: value => AudioService.setMicVolume(value)
        onStepRequested: direction => AudioService.stepMicVolume(direction)
        onButtonClicked: AudioService.toggleMicMute()
    }
}
