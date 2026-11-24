pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: root.adapter !== null
    readonly property bool enabled: root.adapter?.enabled ?? false

    // Named devices: connected first, then paired, then by name.
    readonly property var devices: (root.adapter?.devices.values ?? []).filter(d => d.name.length > 0)
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
    readonly property var connectedDevices: root.devices.filter(d => d.connected)
    // Paired before but not connected now, and never paired.
    readonly property var savedDevices: root.devices.filter(d => !d.connected && (d.paired || d.bonded))
    readonly property var nearbyDevices: root.devices.filter(d => !d.connected && !d.paired && !d.bonded)

    // Device names, first match wins: [pattern, Material Symbol]. Only a fallback for a device BlueZ
    // gives no icon (often one not paired yet), and to tell earbuds from a headset, which BlueZ can't.
    readonly property var nameIcons: [
        [/airpods max|headphone|\bwh-\d|quietcomfort|\bqc ?\d/i, "headphones"],
        [/airpods|buds|earbud|\btws\b|\bwf-\d|\bpods\b/i, "earbuds"],
        [/controller|gamepad|xbox|dualsense|dualshock|8bitdo|joy-?con/i, "sports_esports"],
        [/keyboard|keychron|\bkb\b/i, "keyboard"],
        [/mouse|\bmx (master|anywhere)/i, "mouse"],
        [/watch|\bband\b/i, "watch"],
        [/speaker|soundbar|soundlink/i, "speaker"]
    ]

    // BlueZ's device icon (a freedesktop name, from the device class) to a Material Symbol.
    readonly property var deviceIcons: ({
        "audio-headset": "headset_mic",
        "audio-headphones": "headphones",
        "audio-card": "speaker",
        "input-keyboard": "keyboard",
        "input-mouse": "mouse",
        "input-gaming": "sports_esports",
        "input-tablet": "stylus",
        "phone": "smartphone",
        "computer": "computer",
        "video-display": "tv",
        "camera-video": "videocam",
        "camera-photo": "photo_camera",
        "multimedia-player": "music_note",
        "printer": "print"
    })

    readonly property string icon: !root.enabled ? "bluetooth_disabled" : root.connectedDevices.length > 0 ? "bluetooth_connected" : "bluetooth"
    readonly property string status: !root.available ? "Unavailable" : !root.enabled ? "Off"
        : root.connectedDevices.length > 0 ? root.connectedDevices[0].name : "On"

    function setEnabled(enabled) {
        if (!root.available)
            return;
        root.adapter.enabled = !!enabled;
    }

    // Discovery drains battery; views turn it on only while their list is shown.
    function setDiscovering(discovering) {
        if (root.available && (root.enabled || !discovering))
            root.adapter.discovering = !!discovering;
    }

    // BlueZ's icon comes from the class the device reports, so it wins over a guess from the name.
    function deviceIcon(device) {
        const byClass = root.deviceIcons[device?.icon];
        const byName = root.nameIcons.find(([pattern]) => pattern.test(device?.name ?? ""))?.[1];
        if (!byClass)
            return byName ?? "bluetooth";
        if (["headset_mic", "headphones"].includes(byClass) && ["earbuds", "headphones"].includes(byName))
            return byName;
        return byClass;
    }

    // A connect or disconnect is in flight; Quickshell refuses (and logs) another until it ends.
    function busy(device) {
        return !!device && (device.pairing || device.state === BluetoothDeviceState.Connecting
            || device.state === BluetoothDeviceState.Disconnecting);
    }

    // Only what the device's section doesn't already say: progress, or connected with its battery.
    function deviceStatus(device) {
        if (device.pairing)
            return "Pairing…";
        if (device.state === BluetoothDeviceState.Connecting)
            return "Connecting…";
        if (device.state === BluetoothDeviceState.Disconnecting)
            return "Disconnecting…";
        if (!device.connected)
            return "";
        return device.batteryAvailable ? `Connected · Battery ${Math.round(device.battery * 100)}%` : "Connected";
    }

    // Connected: disconnect. Paired: connect. New: pair.
    function toggleDevice(device) {
        if (!device || root.busy(device))
            return;
        if (device.connected)
            device.disconnect();
        else if (device.paired)
            device.connect();
        else
            device.pair();
    }
}
