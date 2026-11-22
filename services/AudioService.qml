pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

import qs.config

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool sinkReady: root.sink?.audio != null
    readonly property bool sourceReady: root.source?.audio != null

    readonly property real volume: root.sink?.audio?.volume ?? 0
    readonly property bool muted: root.sink?.audio?.muted ?? true
    readonly property bool micMuted: root.source?.audio?.muted ?? true

    readonly property string volumeIcon: {
        if (root.muted)
            return "volume_off";
        if (root.volume <= 0)
            return "volume_mute";
        return root.volume < 0.5 ? "volume_down" : "volume_up";
    }

    readonly property string micIcon: root.micMuted ? "mic_off" : "mic"

    // Apps currently recording (capture streams). Also counts sink-monitor capture, e.g. visualizers.
    readonly property var micUsers: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioInStream)
    readonly property bool micInUse: root.micUsers.length > 0

    // Level 0..1; adjusting the output also unmutes it.
    function setVolume(value) {
        if (!root.sinkReady || !isFinite(value))
            return;
        root.sink.audio.volume = Math.max(0, Math.min(1, value));
        root.sink.audio.muted = false;
    }

    // One Config.services.volumeStep up (+1) or down (-1), from the real level even while muted.
    function step(direction) {
        root.setVolume(root.volume + direction * Config.services.volumeStep / 100);
    }

    function toggleMute() {
        if (root.sink?.audio)
            root.sink.audio.muted = !root.sink.audio.muted;
    }

    function toggleMicMute() {
        if (root.source?.audio)
            root.source.audio.muted = !root.source.audio.muted;
    }

    // qs ipc call volume increase|decrease
    IpcHandler {
        target: "volume"

        function increase(): void {
            root.step(1);
        }

        function decrease(): void {
            root.step(-1);
        }
    }

    // Hyprland: bind = ..., global, ezsh:volumeUp
    GlobalShortcut {
        appid: "ezsh"
        name: "volumeUp"
        description: "Raise volume"
        onPressed: root.step(1)
    }

    GlobalShortcut {
        appid: "ezsh"
        name: "volumeDown"
        description: "Lower volume"
        onPressed: root.step(-1)
    }

    // Nodes must be tracked for their audio properties to be live.
    PwObjectTracker {
        objects: [root.sink, root.source]
    }
}
