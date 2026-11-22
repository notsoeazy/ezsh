pragma Singleton

import QtQuick
import Quickshell

import qs.config

// What the OSD is announcing, and for how long. Levels (volume, brightness) show a slider
// that can be dragged; messages show an icon and text. This decides what and when; each bar
// decides where (focused monitor, not under a view that already shows these controls).
Singleton {
    id: root

    // One row per kind. Levels read and set a 0..1 value on their service; messages build their
    // icon and text from the payload. `enabled` is the kind's Config.osd switch.
    readonly property var kinds: ({
        "volume": {
            level: true,
            enabled: () => Config.osd.volume,
            icon: () => AudioService.volumeIcon,
            value: () => AudioService.muted ? 0 : AudioService.volume,
            set: v => AudioService.setVolume(v),
            step: d => AudioService.step(d)
        },
        "brightness": {
            level: true,
            enabled: () => Config.osd.brightness,
            icon: () => BrightnessService.screenIcon,
            value: () => BrightnessService.screen.value,
            set: v => BrightnessService.screen.set(v),
            step: d => BrightnessService.screen.step(d)
        },
        "keyboardBrightness": {
            level: true,
            enabled: () => Config.osd.keyboardBrightness,
            icon: () => BrightnessService.keyboardIcon,
            value: () => BrightnessService.keyboard.value,
            set: v => BrightnessService.keyboard.set(v),
            step: d => BrightnessService.keyboard.step(d)
        },
        "microphone": {
            enabled: () => Config.osd.microphone,
            icon: p => p.muted ? "mic_off" : "mic",
            text: p => p.muted ? "Microphone muted" : "Microphone on"
        },
        "doNotDisturb": {
            enabled: () => Config.osd.doNotDisturb,
            icon: p => p.enabled ? "notifications_off" : "notifications",
            text: p => p.enabled ? "Do Not Disturb on" : "Do Not Disturb off"
        },
        "nightLight": {
            enabled: () => Config.osd.nightLight,
            icon: p => "nightlight",
            text: p => p.enabled ? "Night light on" : "Night light off"
        },
        "keepAwake": {
            enabled: () => Config.osd.keepAwake,
            icon: p => "coffee",
            text: p => p.enabled ? "Keep awake on" : "Keep awake off"
        }
    })

    // Startup settles many values at once; announce nothing until it has.
    property bool ready: false
    property bool active: false
    property string source: ""
    property var payload: ({})
    // The slider is being dragged: the timeout waits until it is let go.
    property bool held: false

    readonly property var current: root.kinds[root.source] ?? null
    readonly property bool isLevel: root.current?.level === true
    // Levels read live, so the slider follows changes made while it is up.
    readonly property real value: root.isLevel ? root.current.value() : 0
    readonly property string icon: !root.current ? "" : root.isLevel ? root.current.icon() : root.current.icon(root.payload)
    readonly property string text: root.current && !root.isLevel ? root.current.text(root.payload) : ""

    // Show a kind. Night light and keep awake have no service yet; theirs will call
    // announce("nightLight", { enabled }) / announce("keepAwake", { enabled }).
    function announce(kind, payload) {
        const row = root.kinds[kind];
        if (!row) {
            console.warn("OsdService: unknown kind", kind);
            return;
        }
        if (!root.ready || !Config.osd.enabled || !row.enabled())
            return;
        root.source = kind;
        root.payload = payload ?? {};
        root.active = true;
        hideTimer.interval = row.level ? Config.osd.levelTimeout : Config.osd.messageTimeout;
        root.restartTimeout();
    }

    // Set the shown level (slider drag / wheel).
    function set(value) {
        if (!root.active || !root.isLevel)
            return;
        root.current.set(Math.max(0, Math.min(1, value)));
        root.restartTimeout();
    }

    // One service step of the shown level (mouse wheel). Steps from the real level, not the shown
    // one: muted volume shows 0, but a step up should go from where the volume really is.
    function step(direction) {
        if (!root.active || !root.isLevel)
            return;
        root.current.step(direction);
        root.restartTimeout();
    }

    function hold(held) {
        root.held = held;
        root.restartTimeout();
    }

    function dismiss() {
        hideTimer.stop();
        root.held = false;
        root.active = false;
    }

    function restartTimeout() {
        if (root.active && !root.held)
            hideTimer.restart();
        else
            hideTimer.stop();
    }

    Timer {
        id: hideTimer

        onTriggered: root.active = false
    }

    Timer {
        running: true
        interval: Config.osd.startupDelay
        onTriggered: root.ready = true
    }

    Connections {
        target: AudioService

        function onVolumeChanged() {
            if (AudioService.sinkReady)
                root.announce("volume");
        }

        function onMutedChanged() {
            if (AudioService.sinkReady)
                root.announce("volume");
        }

        function onMicMutedChanged() {
            if (AudioService.sourceReady)
                root.announce("microphone", { muted: AudioService.micMuted });
        }
    }

    Connections {
        target: BrightnessService.screen

        function onValueChanged() {
            root.announce("brightness");
        }
    }

    Connections {
        target: BrightnessService.keyboard

        function onValueChanged() {
            root.announce("keyboardBrightness");
        }
    }

    Connections {
        target: NotificationService

        function onDoNotDisturbChanged() {
            root.announce("doNotDisturb", { enabled: NotificationService.doNotDisturb });
        }
    }
}
