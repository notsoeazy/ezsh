pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// shortcut: icon state only; add scanning/connect actions when the network view exists.
Singleton {
    id: root

    readonly property var devices: Networking.devices.values

    readonly property bool wiredConnected: root.devices.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property var wifiDevice: root.devices.find(d => d.type === DeviceType.Wifi) ?? null

    readonly property bool online: root.wiredConnected || root.connectedWifiNetwork !== null

    readonly property var connectedWifiNetwork: {
        if (!root.wifiDevice?.connected)
            return null;
        const networks = root.wifiDevice.networks.values;
        return networks.find(n => n.connected) ?? networks.find(n => n.name === root.activeWifiSsid) ?? null;
    }

    // 0..1
    readonly property real wifiSignalStrength: root.connectedWifiNetwork?.signalStrength ?? 0

    readonly property string icon: {
        if (root.wiredConnected)
            return "lan";
        if (!Networking.wifiEnabled)
            return "wifi_off";
        if (!root.connectedWifiNetwork)
            return "signal_wifi_statusbar_not_connected";
        if (root.wifiSignalStrength > 0.75)
            return "signal_wifi_4_bar";
        if (root.wifiSignalStrength > 0.5)
            return "network_wifi_3_bar";
        if (root.wifiSignalStrength > 0.25)
            return "network_wifi_2_bar";
        return "network_wifi_1_bar";
    }

    // Network.connected stays false on quickshell 0.3.2-git even while the
    // device is connected, so resolve the active SSID from NetworkManager.
    property string activeWifiSsid: ""
    readonly property int wifiDeviceState: root.wifiDevice?.state ?? 0
    onWifiDeviceStateChanged: ssidLookup.running = true

    Process {
        id: ssidLookup

        // `-e no`: SSID is the last field, so unescaped colons in it are harmless.
        command: ["nmcli", "-t", "-e", "no", "-g", "ACTIVE,SSID", "dev", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: root.activeWifiSsid = text.split("\n").find(l => l.startsWith("yes:"))?.slice(4) ?? ""
        }
    }
}
