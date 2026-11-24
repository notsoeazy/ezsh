import QtQuick

import qs
import qs.themes
import qs.services
import qs.components

PanelPage {
    id: root

    readonly property bool discovering: root.shown && BluetoothService.enabled

    title: "Bluetooth"
    accessory: Switch {
        checked: BluetoothService.enabled
        enabled: BluetoothService.available
        Accessible.name: "Bluetooth"
        onToggled: BluetoothService.setEnabled(!BluetoothService.enabled)
    }

    onDiscoveringChanged: BluetoothService.setDiscovering(root.discovering)
    Component.onDestruction: BluetoothService.setDiscovering(false)

    StyledText {
        width: parent.width
        visible: !BluetoothService.available || !BluetoothService.enabled || BluetoothService.devices.length === 0
        wrapText: true
        animateFontSize: false
        text: !BluetoothService.available ? "Bluetooth is unavailable." : !BluetoothService.enabled ? "Bluetooth is off." : "Looking for devices…"
        font.pixelSize: Tokens.fontSize.sm
        color: Theme.color.m3onSurfaceVariant
    }

    PanelList {
        width: parent.width
        sections: !BluetoothService.enabled ? [] : [
            { title: "", values: BluetoothService.connectedDevices },
            { title: "Saved devices", values: BluetoothService.savedDevices },
            { title: "Nearby devices", values: BluetoothService.nearbyDevices }
        ]
        headline: device => device.name
        supportingText: device => BluetoothService.deviceStatus(device)
        leadingIcon: device => BluetoothService.deviceIcon(device)
        trailingIcon: device => device.connected ? "check" : ""
        isSelected: device => device.connected
        onActivated: device => BluetoothService.toggleDevice(device)
    }

    Button {
        width: parent.width
        text: "More settings"
    }
}
