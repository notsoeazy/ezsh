pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Power profiles (power-profiles-daemon) and the battery charge limit (UPower)
Singleton {
    id: root

    property bool conservationAvailable: false
    property bool conservationMode: false
    property bool conservationBusy: false
    property bool conservationError: false

    readonly property var profiles: [
        {
            value: PowerProfile.PowerSaver,
            label: "Power saver",
            icon: "energy_savings_leaf"
        },
        {
            value: PowerProfile.Balanced,
            label: "Balanced",
            icon: "balance"
        },
        {
            value: PowerProfile.Performance,
            label: "Performance",
            icon: "speed"
        }
    ].filter(p => p.value !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)
    readonly property int profile: PowerProfiles.profile
    readonly property var currentProfile: root.profiles.find(p => p.value === root.profile) ?? null

    readonly property var battery: UPower.devices.values.find(d => d.isLaptopBattery && d.isPresent) ?? null
    readonly property string batteryPath: root.battery ? "/org/freedesktop/UPower/devices/battery_" + root.battery.nativePath.replace(/[^A-Za-z0-9_]/g, "_") : ""

    function setProfile(value) {
        if (!root.profiles.some(p => p.value === value))
            return;
        PowerProfiles.profile = value;
    }

    function busctl(verb, args) {
        return ["busctl", "--system", verb, "org.freedesktop.UPower", root.batteryPath, "org.freedesktop.UPower.Device", ...args];
    }

    function refreshConservation() {
        if (!root.batteryPath) {
            root.conservationAvailable = false;
            return;
        }
        conservationRead.command = root.busctl("get-property", ["ChargeThresholdSupported", "ChargeThresholdEnabled"]);
        conservationRead.running = true;
    }

    function setConservationMode(enabled) {
        if (!root.conservationAvailable || root.conservationBusy)
            return;
        root.conservationBusy = true;
        root.conservationError = false;
        conservationWrite.command = root.busctl("call", ["EnableChargeThreshold", "b", enabled ? "true" : "false"]);
        conservationWrite.running = true;
    }

    onBatteryPathChanged: root.refreshConservation()

    Process {
        id: conservationRead

        stdout: StdioCollector {
            onStreamFinished: {
                const values = text.trim().split("\n");
                root.conservationAvailable = values[0] === "b true";
                root.conservationMode = values[1] === "b true";
            }
        }
        onExited: code => {
            if (code !== 0)
                root.conservationAvailable = false;
        }
    }

    Process {
        id: conservationWrite

        onExited: code => {
            if (code !== 0)
                console.warn("PowerService: EnableChargeThreshold failed with code", code);
            root.conservationError = code !== 0;
            root.conservationBusy = false;
            root.refreshConservation();
        }
    }
}
