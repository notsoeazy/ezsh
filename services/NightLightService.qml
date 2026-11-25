pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.config

Singleton {
    id: root

    property bool enabled: false
    property bool adjustPending: false

    readonly property int warmest: 2500
    readonly property int coolest: 6500
    readonly property int step: 100
    // Kept in Config, so the control panel and the settings window share it and it survives restarts.
    readonly property int temperature: Math.max(root.warmest, Math.min(root.coolest, Config.nightLight.temperature))

    function toggle() {
        root.enabled = !root.enabled;
    }

    function setTemperature(kelvin) {
        if (!isFinite(kelvin))
            return;
        const clamped = Math.max(root.warmest, Math.min(root.coolest, Math.round(kelvin / root.step) * root.step));
        if (clamped === root.temperature)
            return;
        Config.nightLight.temperature = clamped;
    }

    // The command is built here, not bound: from onTemperatureChanged a binding may not have updated yet.
    function runAdjust() {
        adjust.command = ["hyprctl", "hyprsunset", "temperature", `${root.temperature}`];
        adjust.running = true;
    }

    function stepTemperature(direction) {
        root.setTemperature(root.temperature + direction * root.step);
    }

    // From the panel, the settings window or an edit to config.json: retune a running hyprsunset.
    onTemperatureChanged: {
        if (!sunset.running)
            return;
        if (adjust.running)
            root.adjustPending = true;
        else
            root.runAdjust();
    }

    Process {
        id: sunset

        running: root.enabled
        command: ["setpriv", "--pdeathsig", "TERM", "hyprsunset", "--temperature", `${root.temperature}`]
        onExited: code => {
            if (root.enabled && code !== 0) {
                console.warn("NightLightService: hyprsunset failed with code", code);
                root.enabled = false;
            }
        }
    }

    Process {
        id: adjust

        onExited: code => {
            if (code !== 0)
                console.warn("NightLightService: hyprctl hyprsunset failed with code", code);
            if (root.adjustPending) {
                root.adjustPending = false;
                root.runAdjust();
            }
        }
    }
}
