pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

Singleton {
    id: root

    property string wiredConnectionName: ""
    property string failedNetwork: ""
    property int failReason: ConnectionFailReason.Unknown
    property string newProfileNetwork: ""
    property string activeWifiSsid: ""

    readonly property var devices: Networking.devices.values
    readonly property var wiredDevice: root.devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property bool wiredConnected: root.wiredDevice !== null
    readonly property string wiredName: root.wiredConnectionName || root.wiredDevice?.name || "Ethernet"
    readonly property int wiredDeviceState: root.wiredDevice?.state ?? 0
    readonly property var wifiDevice: root.devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property bool wifiAvailable: root.wifiDevice !== null
    readonly property bool wifiEnabled: Networking.wifiEnabled

    readonly property bool online: root.wiredConnected || root.connectedWifiNetwork !== null

    readonly property var connectedWifiNetwork: {
        if (!root.wifiDevice?.connected)
            return null;
        const networks = root.wifiDevice.networks.values;
        return networks.find(n => n.connected) ?? networks.find(n => n.name === root.activeWifiSsid) ?? null;
    }

    readonly property var wifiNetworks: (root.wifiDevice?.networks.values ?? []).filter(n => n.name.length > 0)
        .sort((a, b) => ((b === root.connectedWifiNetwork) - (a === root.connectedWifiNetwork)) || (b.signalStrength - a.signalStrength))
    readonly property var savedWifiNetworks: root.wifiNetworks.filter(n => n !== root.connectedWifiNetwork && n.known)
    readonly property var nearbyWifiNetworks: root.wifiNetworks.filter(n => n !== root.connectedWifiNetwork && !n.known)
    readonly property real wifiSignalStrength: root.connectedWifiNetwork?.signalStrength ?? 0

    readonly property string wifiIcon: {
        if (!root.wifiEnabled)
            return "wifi_off";
        if (!root.connectedWifiNetwork)
            return "signal_wifi_statusbar_not_connected";
        return root.signalIcon(root.wifiSignalStrength);
    }

    readonly property string icon: root.wiredConnected ? "lan" : root.wifiIcon

    readonly property string wifiStatus: !root.wifiAvailable ? "Unavailable" : !root.wifiEnabled ? "Off"
        : root.connectedWifiNetwork ? root.connectedWifiNetwork.name : "Not connected"

    readonly property bool failedAuth: root.failedNetwork !== "" && [ConnectionFailReason.NoSecrets, ConnectionFailReason.WifiClientFailed,
        ConnectionFailReason.WifiAuthTimeout].includes(root.failReason)

    readonly property int wifiDeviceState: root.wifiDevice?.state ?? 0

    // Signal strength 0..1 to an icon.
    function signalIcon(strength) {
        if (strength > 0.75)
            return "signal_wifi_4_bar";
        if (strength > 0.5)
            return "network_wifi_3_bar";
        if (strength > 0.25)
            return "network_wifi_2_bar";
        return "network_wifi_1_bar";
    }

    function setWifiEnabled(enabled) {
        if (!root.wifiAvailable)
            return;
        Networking.wifiEnabled = !!enabled;
    }

    // Scanning drains battery; views turn it on only while their list is shown.
    function setScanning(scanning) {
        if (root.wifiDevice)
            root.wifiDevice.scannerEnabled = !!scanning && root.wifiEnabled;
    }

    function secured(network) {
        return !!network && network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe;
    }

    // A secured network needs a password when it isn't saved or its saved one was just rejected.
    function needsPassword(network) {
        return root.secured(network) && (!network.known || (root.failedAuth && network.name === root.failedNetwork));
    }

    // With a password, a saved network gets it written to its profile; an unsaved one gets a new profile.
    function connectTo(network, password) {
        if (!network)
            return;
        root.failedNetwork = "";
        root.failReason = ConnectionFailReason.Unknown;
        root.newProfileNetwork = password && !network.known ? network.name : "";
        if (password)
            network.connectWithPsk(password);
        else
            network.connect();
    }

    function disconnectFrom(network) {
        network?.disconnect();
    }

    // Deletes the saved profile (password included).
    function forget(network) {
        network?.forget();
    }

    // failReason first: the page reads failedAuth when failedNetwork changes. Then drop the profile
    // only if this attempt made it and the key was rejected; a good key lost to a weak signal stays.
    function handleConnectionFailed(network, reason) {
        root.failReason = reason;
        root.failedNetwork = network.name;
        if (network.name !== root.newProfileNetwork)
            return;
        root.newProfileNetwork = "";
        if (root.failedAuth)
            network.forget();
    }

    function lookUpWiredName() {
        root.wiredConnectionName = "";
        if (!root.wiredDevice || wiredNameLookup.running)
            return;
        wiredNameLookup.device = root.wiredDevice.name;
        wiredNameLookup.command = ["nmcli", "-t", "-e", "no", "-g", "GENERAL.CONNECTION", "dev", "show", root.wiredDevice.name];
        wiredNameLookup.running = true;
    }

    onWiredDeviceChanged: root.lookUpWiredName()
    onWiredDeviceStateChanged: root.lookUpWiredName()
    onWifiDeviceStateChanged: ssidLookup.running = true
    // Once the new profile works it is the user's saved network, never to be forgotten on a later drop.
    onConnectedWifiNetworkChanged: {
        if (root.connectedWifiNetwork?.name === root.newProfileNetwork)
            root.newProfileNetwork = "";
    }

    Process {
        id: wiredNameLookup

        // The interface asked about. If the wired device changed meanwhile, the answer is dropped and
        // the row falls back to the interface name rather than showing another device's connection.
        property string device: ""

        // One field with `-e no`, so a colon in the name comes through as is.
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.wiredDevice?.name === wiredNameLookup.device)
                    root.wiredConnectionName = text.trim();
            }
        }
    }

    Process {
        id: ssidLookup

        // `-e no`: SSID is the last field, so unescaped colons in it are harmless.
        command: ["nmcli", "-t", "-e", "no", "-g", "ACTIVE,SSID", "dev", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: root.activeWifiSsid = text.split("\n").find(l => l.startsWith("yes:"))?.slice(4) ?? ""
        }
    }

    // A ScriptModel keeps each network's Connections alive across re-sorts instead of recreating them all.
    Instantiator {
        model: ScriptModel {
            values: root.wifiNetworks
        }

        Connections {
            id: networkConnections

            required property var modelData

            target: networkConnections.modelData

            function onConnectionFailed(reason) {
                root.handleConnectionFailed(networkConnections.modelData, reason);
            }
        }
    }
}
