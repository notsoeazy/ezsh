import QtQuick

import qs
import qs.themes
import qs.services
import qs.components

// The panel's first page: clock and battery, the quick toggles, brightness and volume, the capture
// buttons and the notification count. Right-click the night light toggle for its page.
PanelPage {
    id: root

    readonly property int headerButtonSize: 36
    readonly property int showAllHeight: 32
    readonly property var recordModes: [
        {
            name: "screen",
            label: "Record",
            title: "Screen",
            icon: "desktop_windows"
        },
        {
            name: "sound",
            label: "Record + sound",
            title: "Screen with sound",
            icon: "volume_up"
        },
        {
            name: "region",
            label: "Record area",
            title: "Area",
            icon: "crop"
        }
    ]
    readonly property var recordMode: root.recordModes.find(mode => mode.name === root.recordModeName) ?? root.recordModes[0]

    // shortcut: the capture buttons and mode are UI only, wire them to a capture service (grim + slurp, gpu-screen-recorder) when one exists.
    property string recordModeName: "screen"

    // Asks to leave the panel for another view (the session menu).
    signal navigateRequested(string view)

    function closeOverlay() {
        recordMenu.close();
    }

    showHeader: false
    overlayOpen: recordMenu.shown

    // The menu lives on the window's overlay, so it would outlast the page or the panel fading out.
    onShownChanged: {
        if (!root.shown)
            recordMenu.close();
    }

    Item {
        width: parent.width
        height: clock.height

        Column {
            id: clock

            StyledText {
                animateFontSize: false
                text: TimeService.clockText
                font.pixelSize: Tokens.fontSize.xl
                color: Theme.color.m3onSurface
            }

            StyledText {
                animateFontSize: false
                text: TimeService.longDate
                font.pixelSize: Tokens.fontSize.sm
                color: Theme.color.m3onSurfaceVariant
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spacing.xs

            Button {
                anchors.verticalCenter: parent.verticalCenter
                visible: BatteryService.available
                type: "standard"
                buttonHeight: root.headerButtonSize
                icon: BatteryService.icon
                iconFilled: true
                text: `${Math.round(BatteryService.percentage * 100)}%`
                contentColor: BatteryService.low ? Theme.color.m3error : Theme.color.m3onSurface
                Accessible.name: "Battery"
                onClicked: root.pageRequested("battery")
            }

            // shortcut: no settings view yet, enable this when it lands.
            Button {
                anchors.verticalCenter: parent.verticalCenter
                buttonHeight: root.headerButtonSize
                icon: "settings"
                enabled: false
                Accessible.name: "Settings"
            }

            Button {
                anchors.verticalCenter: parent.verticalCenter
                buttonHeight: root.headerButtonSize
                icon: "power_settings_new"
                Accessible.name: "Power"
                onClicked: root.navigateRequested("session")
            }
        }
    }

    Grid {
        id: tiles

        readonly property real tileWidth: (width - spacing) / 2

        width: parent.width
        columns: 2
        spacing: Tokens.spacing.sm

        QuickTile {
            width: tiles.tileWidth
            title: "Wi-Fi"
            status: NetworkService.wifiStatus
            icon: NetworkService.wifiIcon
            checked: NetworkService.wifiEnabled
            enabled: NetworkService.wifiAvailable
            hasPage: true
            onToggled: NetworkService.setWifiEnabled(!NetworkService.wifiEnabled)
            onOpened: root.pageRequested("wifi")
        }

        QuickTile {
            width: tiles.tileWidth
            title: "Bluetooth"
            status: BluetoothService.status
            icon: BluetoothService.icon
            checked: BluetoothService.enabled
            enabled: BluetoothService.available
            hasPage: true
            onToggled: BluetoothService.setEnabled(!BluetoothService.enabled)
            onOpened: root.pageRequested("bluetooth")
        }

        QuickTile {
            width: tiles.tileWidth
            title: "Keep Awake"
            status: KeepAwakeService.enabled ? "On" : "Off"
            icon: "coffee"
            checked: KeepAwakeService.enabled
            onToggled: KeepAwakeService.toggle()
        }

        QuickTile {
            width: tiles.tileWidth
            title: "Do Not Disturb"
            status: NotificationService.doNotDisturb ? "On" : "Off"
            icon: NotificationService.doNotDisturb ? "notifications_off" : "notifications"
            checked: NotificationService.doNotDisturb
            onToggled: NotificationService.toggleDoNotDisturb()
        }
    }

    LevelRow {
        width: parent.width
        visible: BrightnessService.screenBacklight.available
        icon: BrightnessService.screenIcon
        value: BrightnessService.screenBacklight.level
        buttonIcon: "dark_mode"
        buttonChecked: NightLightService.enabled
        Accessible.name: "Brightness"
        onValueRequested: value => BrightnessService.screenBacklight.setLevel(value)
        onStepRequested: direction => BrightnessService.screenBacklight.stepLevel(direction)
        onButtonClicked: NightLightService.toggle()
        onButtonSecondaryClicked: root.pageRequested("nightlight")
    }

    LevelRow {
        width: parent.width
        sliderEnabled: AudioService.outputReady
        icon: AudioService.volumeIcon
        value: AudioService.outputMuted ? 0 : AudioService.volume
        buttonIcon: AudioService.micIcon
        buttonChecked: AudioService.inputReady && !AudioService.micMuted
        Accessible.name: "Volume"
        onValueRequested: value => AudioService.setVolume(value)
        onStepRequested: direction => AudioService.stepVolume(direction)
        onButtonClicked: AudioService.toggleMicMute()
        onButtonSecondaryClicked: root.pageRequested("audio")
    }

    Item {
        width: parent.width
        height: Tokens.controlPanel.controlHeight

        Button {
            width: (parent.width - Tokens.spacing.sm) / 2
            height: parent.height
            icon: "screenshot_region"
            text: "Screenshot"
        }

        SplitButton {
            id: recordButton

            x: parent.width - width
            width: (parent.width - Tokens.spacing.sm) / 2
            height: parent.height
            icon: "videocam"
            text: root.recordMode.label
            menuOpen: recordMenu.shown
            onMenuRequested: recordMenu.toggle(recordButton.chevron)
        }
    }

    Item {
        width: parent.width
        height: root.showAllHeight

        StyledIcon {
            id: bell

            x: Tokens.spacing.xs
            anchors.verticalCenter: parent.verticalCenter
            text: NotificationService.icon
            color: Theme.color.m3onSurfaceVariant
        }

        StyledText {
            anchors {
                left: bell.right
                right: showAll.left
                leftMargin: Tokens.spacing.sm
                rightMargin: Tokens.spacing.sm
                verticalCenter: parent.verticalCenter
            }

            elideText: true
            animateFontSize: false
            text: NotificationService.count === 0 ? "No notifications" : NotificationService.summaryText
            font.pixelSize: Tokens.fontSize.sm
            color: Theme.color.m3onSurfaceVariant
        }

        // shortcut: no notification view yet, enable this when it lands.
        Button {
            id: showAll

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            buttonHeight: root.showAllHeight
            text: "Show all"
            containerColor: Theme.color.m3surfaceContainerHighest
            enabled: false
        }
    }

    Menu {
        id: recordMenu

        Repeater {
            model: root.recordModes

            MenuItem {
                required property var modelData

                icon: modelData.icon
                text: modelData.title
                selected: modelData.name === root.recordModeName
                onClicked: {
                    root.recordModeName = modelData.name;
                    recordMenu.close();
                }
            }
        }
    }
}
