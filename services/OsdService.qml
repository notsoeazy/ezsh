pragma Singleton

import QtQuick
import Quickshell

import qs
import qs.config

Singleton {
    id: root

    // One row per kind. Levels read and set a 0..1 value on their service; messages build their
    // icon and text from the payload. `enabled` is the kind's Config.osd switch.
    readonly property var kindDefinitions: ({
        "volume": {
            isLevel: true,
            enabled: () => Config.osd.showVolume,
            icon: () => AudioService.volumeIcon,
            level: () => AudioService.outputMuted ? 0 : AudioService.volume,
            setLevel: value => AudioService.setVolume(value),
            stepLevel: direction => AudioService.stepVolume(direction)
        },
        "brightness": {
            isLevel: true,
            enabled: () => Config.osd.showBrightness,
            icon: () => BrightnessService.screenIcon,
            level: () => BrightnessService.screenBacklight.level,
            setLevel: value => BrightnessService.screenBacklight.setLevel(value),
            stepLevel: direction => BrightnessService.screenBacklight.stepLevel(direction)
        },
        "keyboardBrightness": {
            isLevel: true,
            enabled: () => Config.osd.showKeyboardBrightness,
            icon: () => BrightnessService.keyboardIcon,
            level: () => BrightnessService.keyboardBacklight.level,
            setLevel: value => BrightnessService.keyboardBacklight.setLevel(value),
            stepLevel: direction => BrightnessService.keyboardBacklight.stepLevel(direction)
        },
        "microphone": {
            enabled: () => Config.osd.showMicrophone,
            icon: payload => payload.muted ? "mic_off" : "mic",
            text: payload => payload.muted ? "Microphone muted" : "Microphone on"
        },
        "doNotDisturb": {
            enabled: () => Config.osd.showDoNotDisturb,
            icon: payload => payload.enabled ? "notifications_off" : "notifications",
            text: payload => payload.enabled ? "Do Not Disturb on" : "Do Not Disturb off"
        },
        "nightLight": {
            enabled: () => Config.osd.showNightLight,
            icon: () => "nightlight",
            text: payload => payload.enabled ? "Night light on" : "Night light off"
        },
        "keepAwake": {
            enabled: () => Config.osd.showKeepAwake,
            icon: () => "coffee",
            text: payload => payload.enabled ? "Keep awake on" : "Keep awake off"
        }
    })

    property bool startupDelayElapsed: false
    property bool showing: false
    property string currentKind: ""
    property var payload: ({})
    property bool sliderPressed: false

    readonly property var currentDefinition: root.kindDefinitions[root.currentKind] ?? null
    readonly property bool showsLevel: root.currentDefinition?.isLevel === true
    readonly property real level: root.showsLevel ? root.currentDefinition.level() : 0
    readonly property string icon: !root.currentDefinition ? "" : root.showsLevel ? root.currentDefinition.icon() : root.currentDefinition.icon(root.payload)
    readonly property string messageText: root.currentDefinition && !root.showsLevel ? root.currentDefinition.text(root.payload) : ""

    // Show a kind. Night light and keep awake have no service yet; theirs will call
    // announce("nightLight", { enabled }) / announce("keepAwake", { enabled }).
    function announce(kind, payload) {
        const definition = root.kindDefinitions[kind];
        if (!definition) {
            console.warn("OsdService: unknown kind", kind);
            return;
        }
        if (!root.startupDelayElapsed || !Config.osd.enabled || !definition.enabled())
            return;
        root.currentKind = kind;
        root.payload = payload ?? {};
        root.showing = true;
        hideTimer.interval = definition.isLevel ? Config.osd.levelTimeout : Config.osd.messageTimeout;
        root.restartHideTimer();
    }

    // Set the shown level (slider drag / wheel).
    function setLevel(value) {
        if (!root.showing || !root.showsLevel)
            return;
        root.currentDefinition.setLevel(Math.max(0, Math.min(1, value)));
        root.restartHideTimer();
    }

    function stepLevel(direction) {
        if (!root.showing || !root.showsLevel)
            return;
        root.currentDefinition.stepLevel(direction);
        root.restartHideTimer();
    }

    function setSliderPressed(pressed) {
        root.sliderPressed = pressed;
        root.restartHideTimer();
    }

    function dismiss() {
        hideTimer.stop();
        root.sliderPressed = false;
        root.showing = false;
    }

    function restartHideTimer() {
        if (root.showing && !root.sliderPressed)
            hideTimer.restart();
        else
            hideTimer.stop();
    }

    Timer {
        id: hideTimer

        onTriggered: root.showing = false
    }

    Timer {
        running: true
        interval: Tokens.osd.startupDelay
        onTriggered: root.startupDelayElapsed = true
    }

    Connections {
        target: AudioService

        function onVolumeChanged() {
            if (AudioService.outputReady)
                root.announce("volume");
        }

        function onOutputMutedChanged() {
            if (AudioService.outputReady)
                root.announce("volume");
        }

        function onMicMutedChanged() {
            if (AudioService.inputReady)
                root.announce("microphone", { muted: AudioService.micMuted });
        }
    }

    Connections {
        target: BrightnessService.screenBacklight

        function onLevelChanged() {
            root.announce("brightness");
        }
    }

    Connections {
        target: BrightnessService.keyboardBacklight

        function onLevelChanged() {
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
