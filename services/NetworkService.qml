pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

Singleton {
    id: root

    readonly property var devices: Networking.devices.values

    // The connected wired device (a dock can add a second one), or null.
    readonly property var wiredDevice: root.devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property bool wiredConnected: root.wiredDevice !== null
    // NetworkManager's connection name ("Wired connection 1"); Quickshell only knows the interface.
    property string wiredConnectionName: ""
    readonly property string wiredName: root.wiredConnectionName || root.wiredDevice?.name || "Ethernet"
    readonly property int wiredDeviceState: root.wiredDevice?.state ?? 0
    onWiredDeviceChanged: root.lookUpWiredName()
    onWiredDeviceStateChanged: root.lookUpWiredName()
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

    // Named networks in range, the connected one first, then by signal.
    readonly property var wifiNetworks: (root.wifiDevice?.networks.values ?? []).filter(n => n.name.length > 0)
        .sort((a, b) => ((b === root.connectedWifiNetwork) - (a === root.connectedWifiNetwork)) || (b.signalStrength - a.signalStrength))
    // The rest of wifiNetworks, split by whether NetworkManager has a profile for them.
    readonly property var savedWifiNetworks: root.wifiNetworks.filter(n => n !== root.connectedWifiNetwork && n.known)
    readonly property var nearbyWifiNetworks: root.wifiNetworks.filter(n => n !== root.connectedWifiNetwork && !n.known)

    // 0..1
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

    // The name of the last network that refused to connect, and why (ConnectionFailReason); cleared on the next attempt.
    property string failedNetwork: ""
    property int failReason: ConnectionFailReason.Unknown
    // The failure was the supplicant rejecting the key, i.e. most likely a wrong password.
    // (WifiClientDisconnected is left out: it is also what a dropped connection reports.)
    readonly property bool failedAuth: root.failedNetwork !== "" && [ConnectionFailReason.NoSecrets, ConnectionFailReason.WifiClientFailed,
        ConnectionFailReason.WifiAuthTimeout].includes(root.failReason)

    // A network whose saved profile was created by the current password attempt. connectWithPsk saves
    // the profile before trying it, so a wrong password would otherwise be kept and reused silently.
    property string newProfileNetwork: ""

    // Network.connected stays false on quickshell 0.3.2-git even while the
    // device is connected, so resolve the active SSID from NetworkManager.
    property string activeWifiSsid: ""
    readonly property int wifiDeviceState: root.wifiDevice?.state ?? 0
    onWifiDeviceStateChanged: ssidLookup.running = true
    // Once the new profile works it is the user's saved network, never to be forgotten on a later drop.
    onConnectedWifiNetworkChanged: {
        if (root.connectedWifiNetwork?.name === root.newProfileNetwork)
            root.newProfileNetwork = "";
    }

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
            required property var modelData

            target: modelData

            function onConnectionFailed(reason) {
                root.handleConnectionFailed(modelData, reason);
            }
        }
    }
}
