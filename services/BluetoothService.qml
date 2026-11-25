pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

Singleton {
    id: root

    // What views want (setDiscovering); a refresh stops discovery briefly, then returns to this.
    property bool discoveryWanted: false
    // A rename waiting for the one in flight.
    property string queuedName: ""

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: root.adapter !== null
    readonly property bool enabled: root.adapter?.enabled ?? false
    readonly property bool discoverable: root.adapter?.discoverable ?? false
    readonly property string adapterName: root.adapter?.name ?? ""
    // BlueZ caps the name at 248 bytes; this keeps it short enough for any device to show.
    readonly property int maxNameLength: 64
    // True from a refresh until the next one is allowed, however often it is asked for.
    readonly property bool refreshing: refreshCooldown.running
    // How long discovery stays off during a refresh, so BlueZ finishes stopping before it starts again.
    readonly property int restartDelay: 1000
    readonly property int refreshInterval: 5000

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

    // Other devices can find this computer (BlueZ ends it after the adapter's discoverableTimeout).
    function setDiscoverable(discoverable) {
        if (root.available && (root.enabled || !discoverable))
            root.adapter.discoverable = !!discoverable;
    }

    // Unpairs and removes the device.
    function forget(device) {
        if (device && !root.busy(device))
            device.forget();
    }

    // Discovery drains battery; views turn it on only while their list is shown.
    function setDiscovering(discovering) {
        root.discoveryWanted = !!discovering;
        if (root.available && (root.enabled || !discovering) && !restartTimer.running)
            root.adapter.discovering = !!discovering;
    }

    // Restarts discovery, so devices that went quiet are found again. Ignored until refreshInterval has passed.
    function refresh() {
        if (!root.available || !root.enabled || root.refreshing)
            return;
        refreshCooldown.start();
        root.adapter.discovering = false;
        restartTimer.start();
    }

    // The name other devices see for this computer (BlueZ's adapter Alias; Quickshell's is read-only).
    function rename(name) {
        const trimmed = `${name ?? ""}`.trim().slice(0, root.maxNameLength);
        if (!root.available || trimmed === "" || trimmed === root.adapterName)
            return;
        if (renamer.running) {
            root.queuedName = trimmed;
            return;
        }
        renamer.command = ["busctl", "--system", "set-property", "--", "org.bluez", root.adapter.dbusPath, "org.bluez.Adapter1", "Alias", "s", trimmed];
        renamer.running = true;
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

    // Discovery asked for while the adapter was off starts once it turns on.
    onEnabledChanged: {
        if (root.enabled && root.discoveryWanted && !restartTimer.running)
            root.adapter.discovering = true;
    }

    Timer {
        id: restartTimer

        interval: root.restartDelay
        onTriggered: {
            if (root.available && root.enabled)
                root.adapter.discovering = root.discoveryWanted;
        }
    }

    Timer {
        id: refreshCooldown

        interval: root.refreshInterval
    }

    Process {
        id: renamer

        onExited: code => {
            if (code !== 0)
                console.warn("BluetoothService: busctl set-property Alias failed with code", code);
            if (root.queuedName !== "") {
                const next = root.queuedName;
                root.queuedName = "";
                root.rename(next);
            }
        }
    }
}
