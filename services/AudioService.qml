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
    readonly property real micVolume: root.inputNode?.audio?.volume ?? 0
    readonly property real displayVolume: root.outputMuted ? 0 : root.volume
    readonly property real displayMicVolume: root.micMuted ? 0 : root.micVolume

    readonly property var outputDevices: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSink)
        .sort((a, b) => root.deviceName(a).localeCompare(root.deviceName(b)))
    readonly property var inputDevices: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSource)
        .sort((a, b) => root.deviceName(a).localeCompare(root.deviceName(b)))

    readonly property var capturingStreams: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioInStream)
    readonly property bool micInUse: root.capturingStreams.length > 0
    // Apps playing sound, each with its own volume.
    readonly property var playbackStreams: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioOutStream)

    function setNodeVolume(node, value) {
        if (!node?.audio || !isFinite(value))
            return;
        node.audio.volume = Math.max(0, Math.min(Math.max(1, node.audio.volume), value));
        node.audio.muted = false;
    }

    function setVolume(value) {
        root.setNodeVolume(root.outputNode, value);
    }

    function stepVolume(direction) {
        root.setVolume(root.volume + direction * Config.services.volumeStepPercent / 100);
    }

    function setOutputMuted(muted) {
        if (root.outputNode?.audio)
            root.outputNode.audio.muted = !!muted;
    }

    function setMicMuted(muted) {
        if (root.inputNode?.audio)
            root.inputNode.audio.muted = !!muted;
    }

    function toggleOutputMute() {
        if (root.outputNode?.audio)
            root.outputNode.audio.muted = !root.outputNode.audio.muted;
    }

    function toggleMicMute() {
        if (root.inputNode?.audio)
            root.inputNode.audio.muted = !root.inputNode.audio.muted;
    }

    function setMicVolume(value) {
        root.setNodeVolume(root.inputNode, value);
    }

    function stepMicVolume(direction) {
        root.setMicVolume(root.micVolume + direction * Config.services.volumeStepPercent / 100);
    }

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

    // The app behind a playback stream.
    function streamName(node) {
        return node?.properties?.["application.name"] || root.deviceName(node);
    }

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

    IpcHandler {
        target: "volume"

        function increase(): void {
            root.stepVolume(1);
        }

        function decrease(): void {
            root.stepVolume(-1);
        }

        function toggleMute(): void {
            root.toggleOutputMute();
        }
    }

    IpcHandler {
        target: "mic"

        function toggleMute(): void {
            root.toggleMicMute();
        }
    }

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

    GlobalShortcut {
        appid: "ezsh"
        name: "volumeMute"
        description: "Mute or unmute the output"
        onPressed: root.toggleOutputMute()
    }

    GlobalShortcut {
        appid: "ezsh"
        name: "micMute"
        description: "Mute or unmute the microphone"
        onPressed: root.toggleMicMute()
    }

    PwObjectTracker {
        // Stream volumes are only live while tracked; few apps play at once.
        objects: [root.outputNode, root.inputNode, ...root.playbackStreams]
    }
}
