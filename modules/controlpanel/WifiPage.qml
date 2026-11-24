import QtQuick

import qs
import qs.themes
import qs.services
import qs.components

PanelPage {
    id: root

    readonly property bool scanning: root.shown && NetworkService.wifiEnabled
    readonly property bool showsStatus: root.joining || NetworkService.failedNetwork !== ""

    property var pendingNetwork: null
    property bool joining: false
    property string statusText: ""
    property string pendingName: ""

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

    Binding {
        when: root.showsStatus
        target: root
        property: "statusText"
        value: root.joining ? `Connecting to ${root.pendingNetwork?.name ?? ""}…`
            : NetworkService.failedAuth ? `Wrong password for ${NetworkService.failedNetwork}`
            : `Couldn't connect to ${NetworkService.failedNetwork}`
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: root.pendingNetwork !== null
        target: root
        property: "pendingName"
        value: root.pendingNetwork?.name ?? ""
        restoreMode: Binding.RestoreNone
    }
    Component.onDestruction: NetworkService.setScanning(false)

    Reveal {
        id: wifiNotice

        width: parent.width
        vertical: true
        columnSpacing: parent.spacing
        revealed: !NetworkService.wifiAvailable || !NetworkService.wifiEnabled || NetworkService.wifiNetworks.length === 0

        StyledText {
            width: parent.width
            wrapText: true
            animateFontSize: false
            animateTextChange: wifiNotice.progress === 1
            text: !NetworkService.wifiAvailable ? "Wi-Fi is unavailable." : !NetworkService.wifiEnabled ? "Wi-Fi is off." : "Looking for networks…"
            font.pixelSize: Tokens.fontSize.sm
            color: Theme.color.m3onSurfaceVariant
        }
    }

    Reveal {
        width: parent.width
        vertical: true
        columnSpacing: parent.spacing
        revealed: root.showsStatus

        StyledText {
            width: parent.width
            elideText: true
            animateFontSize: false
            animateTextChange: true
            text: root.statusText
            font.pixelSize: Tokens.fontSize.sm
            color: root.joining ? Theme.color.m3onSurfaceVariant : Theme.color.m3error
        }
    }

    Reveal {
        width: parent.width
        vertical: true
        columnSpacing: parent.spacing
        revealed: root.pendingNetwork !== null

        SearchBar {
            id: password

            width: parent.width
            icon: "key"
            placeholder: `Password for ${root.pendingName}`
            echoMode: TextInput.Password
            onAccepted: root.join()
            onEscapePressed: root.cancelJoin()
        }
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
