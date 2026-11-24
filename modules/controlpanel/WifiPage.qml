import QtQuick

import qs
import qs.themes
import qs.services
import qs.components

// Nearby Wi-Fi networks. Click one to join it (asking for a password when it is secured and not
// saved) or, when connected, to disconnect.
PanelPage {
    id: root

    // Scan only while the list is on screen and Wi-Fi is on.
    readonly property bool scanning: root.shown && NetworkService.wifiEnabled

    // The secured network waiting for its password, or null.
    property var pendingNetwork: null
    // A password was sent for pendingNetwork and NetworkManager hasn't answered yet.
    property bool joining: false

    function activate(network) {
        if (network === NetworkService.connectedWifiNetwork) {
            NetworkService.disconnectFrom(network);
        } else if (NetworkService.needsPassword(network)) {
            root.pendingNetwork = network;
            root.joining = false;
            password.text = "";
            password.forceActiveFocus();
        } else {
            root.cancelJoin();
            NetworkService.connectTo(network, "");
        }
    }

    // The field stays open until the network connects, so a wrong password can be retyped.
    function join() {
        if (password.text === "" || !root.pendingNetwork)
            return;
        root.joining = true;
        NetworkService.connectTo(root.pendingNetwork, password.text);
    }

    function cancelJoin() {
        root.pendingNetwork = null;
        root.joining = false;
        password.text = "";
        // Hand the keyboard back to the panel so Esc still goes back.
        root.forceActiveFocus();
    }

    title: "Wi-Fi"
    accessory: Switch {
        checked: NetworkService.wifiEnabled
        enabled: NetworkService.wifiAvailable
        Accessible.name: "Wi-Fi"
        onToggled: NetworkService.setWifiEnabled(!NetworkService.wifiEnabled)
    }

    onScanningChanged: NetworkService.setScanning(root.scanning)
    Component.onDestruction: NetworkService.setScanning(false)

    StyledText {
        width: parent.width
        visible: !NetworkService.wifiAvailable || !NetworkService.wifiEnabled || NetworkService.wifiNetworks.length === 0
        wrapText: true
        animateFontSize: false
        text: !NetworkService.wifiAvailable ? "Wi-Fi is unavailable." : !NetworkService.wifiEnabled ? "Wi-Fi is off." : "Looking for networks…"
        font.pixelSize: Tokens.fontSize.sm
        color: Theme.color.m3onSurfaceVariant
    }

    StyledText {
        width: parent.width
        visible: root.joining || NetworkService.failedNetwork !== ""
        elideText: true
        animateFontSize: false
        text: root.joining ? `Connecting to ${root.pendingNetwork?.name ?? ""}…`
            : NetworkService.failedAuth ? `Wrong password for ${NetworkService.failedNetwork}`
            : `Couldn't connect to ${NetworkService.failedNetwork}`
        font.pixelSize: Tokens.fontSize.sm
        color: root.joining ? Theme.color.m3onSurfaceVariant : Theme.color.m3error
    }

    SearchBar {
        id: password

        width: parent.width
        visible: root.pendingNetwork !== null
        icon: "key"
        placeholder: `Password for ${root.pendingNetwork?.name ?? ""}`
        echoMode: TextInput.Password
        onAccepted: root.join()
        onEscapePressed: root.cancelJoin()
    }

    PanelList {
        width: parent.width
        sections: !NetworkService.wifiEnabled ? [] : [
            { title: "", values: NetworkService.connectedWifiNetwork ? [NetworkService.connectedWifiNetwork] : [] },
            { title: "Saved networks", values: NetworkService.savedWifiNetworks },
            { title: "Nearby networks", values: NetworkService.nearbyWifiNetworks }
        ]
        headline: network => network.name
        supportingText: network => network === NetworkService.connectedWifiNetwork ? "Connected" : ""
        leadingIcon: network => NetworkService.signalIcon(network.signalStrength)
        trailingIcon: network => network === NetworkService.connectedWifiNetwork ? "check" : NetworkService.secured(network) ? "lock" : ""
        isSelected: network => network === NetworkService.connectedWifiNetwork
        onActivated: network => root.activate(network)

        // The wired link sits with the active connection; shown only while it is up, so it isn't clickable.
        ListItem {
            width: parent.width
            visible: NetworkService.wiredConnected
            interactive: false
            selected: true
            icon: "lan"
            headline: NetworkService.wiredName
            supportingText: "Ethernet · Connected"
            trailingIcon: "check"
        }
    }

    // shortcut: does nothing until the settings view exists; route it to the network tab then.
    Button {
        width: parent.width
        text: "More settings"
    }

    Connections {
        target: NetworkService

        function onConnectedWifiNetworkChanged() {
            if (root.pendingNetwork && NetworkService.connectedWifiNetwork === root.pendingNetwork)
                root.cancelJoin();
        }

        function onFailedNetworkChanged() {
            if (!root.joining || NetworkService.failedNetwork !== root.pendingNetwork?.name)
                return;
            root.joining = false;
            password.selectAll();
            password.forceActiveFocus();
        }
    }
}
