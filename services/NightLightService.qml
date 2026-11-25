pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.config

Singleton {
    id: root

    property bool enabled: false
    property int temperature: Math.max(root.warmest, Math.min(root.coolest, Config.nightLight.temperature))
    property bool adjustPending: false

    readonly property int warmest: 2500
    readonly property int coolest: 6500
    readonly property int step: 100

    function toggle() {
        root.enabled = !root.enabled;
    }

    function setTemperature(kelvin) {
        if (!isFinite(kelvin))
            return;
        root.temperature = Math.max(root.warmest, Math.min(root.coolest, Math.round(kelvin / root.step) * root.step));
        if (!sunset.running)
            return;
        if (adjust.running)
            root.adjustPending = true;
        else
            adjust.running = true;
    }

    function stepTemperature(direction) {
        root.setTemperature(root.temperature + direction * root.step);
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

        command: ["hyprctl", "hyprsunset", "temperature", `${root.temperature}`]
        onExited: code => {
            if (code !== 0)
                console.warn("NightLightService: hyprctl hyprsunset failed with code", code);
            if (root.adjustPending) {
                root.adjustPending = false;
                adjust.running = true;
            }
        }
    }
}
