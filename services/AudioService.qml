pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

import qs.config

Singleton {
    id: root

    readonly property PwNode outputNode: Pipewire.defaultAudioSink
    readonly property PwNode inputNode: Pipewire.defaultAudioSource

    readonly property bool outputReady: root.outputNode?.audio != null
    readonly property bool inputReady: root.inputNode?.audio != null

    readonly property real volume: root.outputNode?.audio?.volume ?? 0
    readonly property bool outputMuted: root.outputNode?.audio?.muted ?? true
    readonly property bool micMuted: root.inputNode?.audio?.muted ?? true

    readonly property string volumeIcon: {
        if (root.outputMuted)
            return "volume_off";
        if (root.volume <= 0)
            return "volume_mute";
        return root.volume < 0.5 ? "volume_down" : "volume_up";
    }

    readonly property string micIcon: root.micMuted ? "mic_off" : "mic"
    // 0..1
    readonly property real micVolume: root.inputNode?.audio?.volume ?? 0

    // Devices (not app streams), by name.
    // shortcut: Quickshell types only exact "Audio/Source", so virtual mics ("Audio/Source/Virtual":
    // EasyEffects, noise suppression) are left out and can't be made default; set them with wpctl if needed.
    readonly property var outputDevices: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSink)
        .sort((a, b) => root.deviceName(a).localeCompare(root.deviceName(b)))
    readonly property var inputDevices: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSource)
        .sort((a, b) => root.deviceName(a).localeCompare(root.deviceName(b)))

    // Apps currently recording (capture streams). Also counts sink-monitor capture, e.g. visualizers.
    readonly property var capturingStreams: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioInStream)
    readonly property bool micInUse: root.capturingStreams.length > 0

    // Level 0..1; adjusting the output also unmutes it.
    function setVolume(value) {
        if (!root.outputReady || !isFinite(value))
            return;
        // Up to 100%, or the current level if it was boosted past that, so stepping up never lowers it.
        root.outputNode.audio.volume = Math.max(0, Math.min(Math.max(1, root.volume), value));
        root.outputNode.audio.muted = false;
    }

    // One Config.services.volumeStepPercent up (+1) or down (-1), from the real level even while muted.
    function stepVolume(direction) {
        root.setVolume(root.volume + direction * Config.services.volumeStepPercent / 100);
    }

    function toggleOutputMute() {
        if (root.outputNode?.audio)
            root.outputNode.audio.muted = !root.outputNode.audio.muted;
    }

    function toggleMicMute() {
        if (root.inputNode?.audio)
            root.inputNode.audio.muted = !root.inputNode.audio.muted;
    }

    // Level 0..1; adjusting the mic also unmutes it.
    function setMicVolume(value) {
        if (!root.inputReady || !isFinite(value))
            return;
        root.inputNode.audio.volume = Math.max(0, Math.min(Math.max(1, root.micVolume), value));
        root.inputNode.audio.muted = false;
    }

    function stepMicVolume(direction) {
        root.setMicVolume(root.micVolume + direction * Config.services.volumeStepPercent / 100);
    }

    // Pipewire moves streams that follow the default to the new device.
    function setOutputDevice(node) {
        if (node?.type === PwNodeType.AudioSink)
            Pipewire.preferredDefaultAudioSink = node;
    }

    function setInputDevice(node) {
        if (node?.type === PwNodeType.AudioSource)
            Pipewire.preferredDefaultAudioSource = node;
    }

    function deviceName(node) {
        return node?.description || node?.nickname || node?.name || "Unknown device";
    }

    // From the node name, which says the bus (bluez_output.…, alsa_output.…hdmi…).
    function deviceIcon(node) {
        const name = node?.name ?? "";
        if (name.startsWith("bluez"))
            return node.type === PwNodeType.AudioSink ? "headphones" : "headset_mic";
        if (name.includes("hdmi") || name.includes("displayport"))
            return "tv";
        if (name.includes("usb"))
            return node.type === PwNodeType.AudioSink ? "headphones" : "mic_external_on";
        return node?.type === PwNodeType.AudioSink ? "speaker" : "mic";
    }

    // qs ipc call volume increase|decrease
    IpcHandler {
        target: "volume"

        function increase(): void {
            root.stepVolume(1);
        }

        function decrease(): void {
            root.stepVolume(-1);
        }
    }

    // Hyprland: bind = ..., global, ezsh:volumeUp
    GlobalShortcut {
        appid: "ezsh"
        name: "volumeUp"
        description: "Raise volume"
        onPressed: root.stepVolume(1)
    }

    GlobalShortcut {
        appid: "ezsh"
        name: "volumeDown"
        description: "Lower volume"
        onPressed: root.stepVolume(-1)
    }

    // Nodes must be tracked for their audio properties to be live.
    PwObjectTracker {
        objects: [root.outputNode, root.inputNode]
    }
}
