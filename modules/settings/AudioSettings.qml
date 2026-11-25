import QtQuick

import qs.services

SettingsPage {
    id: root

    name: "audio"
    title: "Audio"
    icon: "volume_up"
    description: "Output and input devices, their levels, and each app's volume."
    sections: [
        {
            title: "Output",
            rows: [
                root.levelRow("Volume", () => AudioService.volumeIcon, () => AudioService.volume, value => AudioService.setVolume(value)),
                { type: "switch", label: "Mute", icon: "volume_off", get: () => AudioService.outputMuted, set: value => AudioService.setOutputMuted(value) },
                ...AudioService.outputDevices.map(node => root.deviceRow(node, () => AudioService.outputNode === node, () => AudioService.setOutputDevice(node)))
            ]
        },
        {
            title: "Input",
            rows: [
                root.levelRow("Microphone", () => AudioService.micIcon, () => AudioService.micVolume, value => AudioService.setMicVolume(value)),
                { type: "switch", label: "Mute microphone", icon: "mic_off", get: () => AudioService.micMuted, set: value => AudioService.setMicMuted(value) },
                ...AudioService.inputDevices.map(node => root.deviceRow(node, () => AudioService.inputNode === node, () => AudioService.setInputDevice(node)))
            ]
        },
        ...(AudioService.playbackStreams.length > 0 ? [{
            title: "Apps",
            rows: AudioService.playbackStreams.map(node => ({
                type: "slider",
                label: AudioService.streamName(node),
                icon: "music_note",
                description: () => node.properties?.["media.name"] ?? "",
                get: () => Math.round((node.audio?.volume ?? 0) * 100),
                set: value => AudioService.setNodeVolume(node, value / 100),
                min: 0,
                max: 100,
                step: 1,
                unit: "%"
            }))
        }] : []),
        {
            title: "Keys",
            rows: [
                { type: "number", label: "Volume key step", icon: "keyboard", key: "services.volumeStepPercent", min: 1, max: 100, step: 1, unit: "%" }
            ]
        }
    ]

    function levelRow(label, icon, level, setLevel) {
        return { type: "slider", label: label, icon: icon, get: () => Math.round(level() * 100), set: value => setLevel(value / 100), min: 0, max: 100, step: 1, unit: "%" };
    }

    function deviceRow(node, chosen, choose) {
        return { type: "radio", label: AudioService.deviceName(node), icon: AudioService.deviceIcon(node), get: chosen, run: choose };
    }
}
