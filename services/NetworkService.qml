pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

import "nmcli.js" as Nmcli

// shortcut: icon state only; add scanning/connect actions when the network view exists.
Singleton {
    id: root

    readonly property var devices: Networking.devices.values

    readonly property bool wiredConnected: root.devices.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property var wifiDevice: root.devices.find(d => d.type === DeviceType.Wifi) ?? null

    readonly property bool connected: root.wiredConnected || root.wifiNetwork !== null

    readonly property var wifiNetwork: {
        if (!root.wifiDevice?.connected)
            return null;
        const nets = root.wifiDevice.networks.values;
        return nets.find(n => n.connected) ?? nets.find(n => n.name === root.activeSsid) ?? null;
    }

    // 0..1
    readonly property real signalStrength: root.wifiNetwork?.signalStrength ?? 0

    readonly property string icon: {
        if (root.wiredConnected)
            return "lan";
        if (!Networking.wifiEnabled)
            return "wifi_off";
        if (!root.wifiNetwork)
            return "signal_wifi_statusbar_not_connected";
        if (root.signalStrength > 0.75)
            return "signal_wifi_4_bar";
        if (root.signalStrength > 0.5)
            return "network_wifi_3_bar";
        if (root.signalStrength > 0.25)
            return "network_wifi_2_bar";
        return "network_wifi_1_bar";
    }

    // Network.connected stays false on quickshell 0.3.2-git even while the
    // device is connected, so resolve the active SSID from NetworkManager.
    property string activeSsid: ""
    readonly property int wifiState: root.wifiDevice?.state ?? 0
    onWifiStateChanged: ssidProc.running = true

    Process {
        id: ssidProc

        command: ["nmcli", "-t", "-g", "ACTIVE,SSID", "dev", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: root.activeSsid = Nmcli.activeSsid(text)
        }
    }
}
