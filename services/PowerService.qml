pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Power profiles (power-profiles-daemon)
Singleton {
    id: root

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

    readonly property string conservationPath: "/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"

    property bool conservationAvailable: false
    property bool conservationWritable: false
    property bool conservationMode: false

    function setProfile(value) {
        if (!root.profiles.some(p => p.value === value))
            return;
        PowerProfiles.profile = value;
    }

    function setConservationMode(enabled) {
        if (!root.conservationAvailable || !root.conservationWritable)
            return;
        conservationFile.setText(enabled ? "1" : "0");
    }

    // sysfs sends no change events: re-read when the value is about to be shown, and re-check
    // write access (the udev rule or a chmod may have been applied since).
    function refreshConservation() {
        if (!root.conservationAvailable)
            return;
        conservationFile.reload();
        writableCheck.running = true;
    }

    FileView {
        id: conservationFile

        path: root.conservationPath
        // sysfs attributes can't be replaced by a renamed temp file.
        atomicWrites: false
        // Absent on every machine but these Lenovos; that is not an error.
        printErrors: false

        onLoaded: {
            root.conservationMode = conservationFile.text().trim() === "1";
            if (!root.conservationAvailable) {
                root.conservationAvailable = true;
                writableCheck.running = true;
            }
        }
        onLoadFailed: root.conservationAvailable = false
        // A reload() from here is ignored, so take the state from what was written: the kernel
        // rejects a bad write, so a successful one is the new value.
        onSaved: root.conservationMode = conservationFile.text().trim() === "1"
        onSaveFailed: {
            console.warn("ConservationMode: could not write", root.conservationPath, "(install scripts/99-ezsh-conservation-mode.rules)");
            root.conservationWritable = false;
            conservationFile.reload();
        }
    }

    Process {
        id: writableCheck

        command: ["test", "-w", root.conservationPath]
        onExited: code => root.conservationWritable = code === 0
    }
}
