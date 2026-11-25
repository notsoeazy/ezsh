pragma Singleton

import QtQuick
import Quickshell

import qs
import qs.config

Singleton {
    id: root

    property bool startupDelayElapsed: false
    property bool showing: false
    property string currentKind: ""
    property var payload: ({})
    property bool sliderPressed: false
    // The focused bar can't show the OSD right now (a view covers it); a held message keeps its full time for when it can.
    property bool held: false

    // One row per kind. Levels read and set a 0..1 value on their service; messages build their
    // icon and text from the payload. `enabled` is the kind's Config.osd switch.
    readonly property var kindDefinitions: ({
        "volume": {
            isLevel: true,
            enabled: () => Config.osd.showVolume,
            icon: () => AudioService.volumeIcon,
            level: () => AudioService.displayVolume,
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
        "powerProfile": {
            enabled: () => Config.osd.showPowerProfile,
            icon: payload => payload.icon,
            text: payload => payload.label
        },
        "conservationMode": {
            enabled: () => Config.osd.showConservationMode,
            icon: () => "battery_saver",
            text: payload => payload.enabled ? "Battery charge limit on" : "Battery charge limit off"
        },
        "keepAwake": {
            enabled: () => Config.osd.showKeepAwake,
            icon: () => "coffee",
            text: payload => payload.enabled ? "Keep awake on" : "Keep awake off"
        },
        "capture": {
            enabled: () => Config.osd.showCapture,
            icon: payload => payload.icon,
            text: payload => payload.text
        }
    })

    readonly property var currentDefinition: root.kindDefinitions[root.currentKind] ?? null
    readonly property bool showsLevel: root.currentDefinition?.isLevel === true
    readonly property real level: root.showsLevel ? root.currentDefinition.level() : 0
    readonly property string icon: !root.currentDefinition ? "" : root.showsLevel ? root.currentDefinition.icon() : root.currentDefinition.icon(root.payload)
    readonly property string messageText: root.currentDefinition && !root.showsLevel ? root.currentDefinition.text(root.payload) : ""

    // Show a kind.
    function announce(kind, payload) {
        const definition = root.kindDefinitions[kind];
        if (!definition) {
            console.warn("OsdService: unknown kind", kind);
            return;
        }
        if (!root.startupDelayElapsed || !Config.osd.enabled || !definition.enabled())
            return;
        // Payload first: the kind's icon/text bindings read it as soon as currentKind changes.
        root.payload = payload ?? {};
        root.currentKind = kind;
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
        root.held = false;
        root.showing = false;
    }

    function setBlocked(blocked) {
        if (blocked && root.showsLevel) {
            root.dismiss();
            return;
        }
        root.held = blocked;
        root.restartHideTimer();
    }

    function restartHideTimer() {
        if (root.showing && !root.sliderPressed && !root.held)
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
        interval: Config.osd.startupDelay
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

    Connections {
        target: NightLightService

        function onEnabledChanged() {
            root.announce("nightLight", { enabled: NightLightService.enabled });
        }
    }

    Connections {
        target: PowerService

        // Not onProfileChanged: currentProfile may not have followed profile yet when that fires.
        function onCurrentProfileChanged() {
            if (PowerService.currentProfile)
                root.announce("powerProfile", PowerService.currentProfile);
        }

        function onConservationModeChanged() {
            root.announce("conservationMode", { enabled: PowerService.conservationMode });
        }
    }

    Connections {
        target: KeepAwakeService

        function onEnabledChanged() {
            root.announce("keepAwake", { enabled: KeepAwakeService.enabled });
        }
    }
}
