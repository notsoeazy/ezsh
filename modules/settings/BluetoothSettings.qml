import QtQuick

import qs.services

// The adapter and its devices; discovery runs only while the page is shown.
SettingsPage {
    id: root

    name: "bluetooth"
    title: "Bluetooth"
    icon: "bluetooth"
    description: "Pair, connect and forget devices."
    sections: [
        {
            title: "",
            rows: [
                {
                    type: "text",
                    label: "Device name",
                    description: "How other devices see this computer.",
                    placeholder: "Name",
                    get: () => BluetoothService.adapterName,
                    set: value => BluetoothService.rename(value)
                },
                {
                    type: "switch",
                    label: "Bluetooth",
                    icon: () => BluetoothService.icon,
                    description: () => BluetoothService.available ? "" : "No adapter found",
                    get: () => BluetoothService.enabled,
                    set: value => BluetoothService.setEnabled(value)
                },
                {
                    type: "switch",
                    label: "Visible to other devices",
                    description: "Lets new devices find this computer, until the adapter's timeout.",
                    get: () => BluetoothService.discoverable,
                    set: value => BluetoothService.setDiscoverable(value)
                }
            ]
        },
        ...(BluetoothService.connectedDevices.length > 0 ? [{
            title: "Connected",
            rows: BluetoothService.connectedDevices.map(device => root.deviceRow(device, [root.button("Disconnect", device), root.forgetButton(device)]))
        }] : []),
        ...(BluetoothService.savedDevices.length > 0 ? [{
            title: "Paired",
            rows: BluetoothService.savedDevices.map(device => root.deviceRow(device, [root.button("Connect", device), root.forgetButton(device)]))
        }] : []),
        ...(BluetoothService.enabled ? [{
            title: "Nearby",
            rows: [
                {
                    type: "action",
                    label: "Search for devices",
                    description: () => BluetoothService.refreshing ? "Searching again…" : "Devices in pairing mode show up here.",
                    buttons: [{ text: "Refresh", enabled: () => !BluetoothService.refreshing, run: () => BluetoothService.refresh() }]
                },
                ...BluetoothService.nearbyDevices.map(device => root.deviceRow(device, [root.button("Pair", device)]))
            ]
        }] : [])
    ]

    function deviceRow(device, buttons) {
        return {
            type: "action",
            label: device.name,
            icon: () => BluetoothService.deviceIcon(device),
            description: () => BluetoothService.deviceStatus(device) || device.address,
            buttons: buttons
        };
    }

    // Connect, disconnect or pair, whichever the device's state calls for.
    function button(text, device) {
        return { text: text, enabled: () => !BluetoothService.busy(device), run: () => BluetoothService.toggleDevice(device) };
    }

    function forgetButton(device) {
        return { text: "Forget", enabled: () => !BluetoothService.busy(device), run: () => BluetoothService.forget(device) };
    }

    onShownChanged: BluetoothService.setDiscovering(root.shown)
}
