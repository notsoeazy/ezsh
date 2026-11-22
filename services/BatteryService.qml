pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice

    readonly property bool available: root.device.ready && root.device.isLaptopBattery
    readonly property real percentage: root.device.percentage // 0..1
    // Low: on battery power at 20% or less.
    readonly property bool low: root.available && UPower.onBattery && root.percentage <= 0.2
    readonly property bool charging: root.device.state === UPowerDeviceState.Charging || root.device.state === UPowerDeviceState.FullyCharged

    readonly property string icon: {
        if (root.charging)
            return "battery_charging_full";
        if (root.percentage >= 0.95)
            return "battery_full";
        return `battery_${Math.round(root.percentage * 6)}_bar`;
    }
}
