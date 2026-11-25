import QtQuick

import qs.services

// Wi-Fi and Ethernet. Rows are rebuilt as networks come and go, so scanning pauses while a password is typed.
SettingsPage {
    id: root

    // The nearby secured network a password is being typed for.
    property var passwordFor: null

    readonly property var connected: NetworkService.connectedWifiNetwork

    name: "network"
    title: "Network"
    icon: "wifi"
    description: "Wi-Fi networks, saved passwords and the wired connection."
    sections: [
        {
            title: "",
            rows: [
                {
                    type: "switch",
                    label: "Wi-Fi",
                    icon: () => NetworkService.wifiIcon,
                    description: () => NetworkService.wifiStatus,
                    get: () => NetworkService.wifiEnabled,
                    set: value => NetworkService.setWifiEnabled(value)
                },
                {
                    type: "info",
                    label: "Ethernet",
                    icon: "lan",
                    description: () => NetworkService.wiredConnected ? NetworkService.wiredName : "",
                    get: () => NetworkService.wiredConnected ? "Connected" : "Not connected"
                }
            ]
        },
        ...(root.connected ? [{
            title: "Connected",
            rows: [root.networkRow(root.connected, [{ text: "Disconnect", run: () => NetworkService.disconnectFrom(root.connected) }, root.forgetButton(root.connected)])]
        }] : []),
        ...(NetworkService.savedWifiNetworks.length > 0 ? [{
            title: "Saved",
            rows: NetworkService.savedWifiNetworks.map(network => root.networkRow(network, [root.connectButton(network), root.forgetButton(network)]))
        }] : []),
        ...(NetworkService.nearbyWifiNetworks.length > 0 || root.passwordFor ? [{
            title: "Nearby",
            rows: [
                ...(root.passwordFor ? [{
                    type: "text",
                    label: `Password for ${root.passwordFor.name}`,
                    description: "Enter connects, Esc clears.",
                    icon: "key",
                    placeholder: "Password",
                    secret: true,
                    focused: true,
                    fromText: text => {
                        if (text !== "") {
                            NetworkService.connectTo(root.passwordFor, text);
                            root.passwordFor = null;
                        }
                        return undefined;
                    }
                }] : []),
                ...NetworkService.nearbyWifiNetworks.map(network => root.networkRow(network, [root.connectButton(network)]))
            ]
        }] : [])
    ]

    function networkRow(network, buttons) {
        return {
            type: "action",
            label: network.name,
            icon: () => NetworkService.signalIcon(network.signalStrength),
            description: () => {
                if (NetworkService.failedNetwork === network.name)
                    return NetworkService.failedAuth ? "Wrong password" : "Couldn't connect";
                if (network.stateChanging)
                    return network.connected ? "Disconnecting…" : "Connecting…";
                return NetworkService.secured(network) ? "Secured" : "Open";
            },
            buttons: buttons
        };
    }

    function connectButton(network) {
        if (root.passwordFor === network)
            return { text: "Cancel", run: () => root.passwordFor = null };
        return {
            text: "Connect",
            enabled: () => !network.stateChanging,
            run: () => {
                if (NetworkService.needsPassword(network))
                    root.passwordFor = network;
                else
                    NetworkService.connectTo(network, "");
            }
        };
    }

    function forgetButton(network) {
        return { text: "Forget", run: () => NetworkService.forget(network) };
    }

    onShownChanged: NetworkService.setScanning(root.shown && !root.passwordFor)
    onPasswordForChanged: NetworkService.setScanning(root.shown && !root.passwordFor)
}
