import QtQuick

import qs
import qs.services
import qs.components

Item {
    id: root

    readonly property int panelWidth: 440
    readonly property int contentPadding: Tokens.spacing.md
    // Each page is loaded only while shown (PageSlot).
    readonly property var pages: ({
            home: homeSlot,
            wifi: wifiSlot,
            bluetooth: bluetoothSlot,
            nightlight: nightLightSlot,
            battery: batterySlot,
            audio: audioSlot
        })
    readonly property PanelPage page: root.pages[root.pageName]?.item ?? null
    readonly property bool open: ViewService.view === "controlpanel"
    // Its sliders change the levels the OSD shows; the OSD would cover the panel.
    readonly property bool coversOsd: true
    // A Menu hangs outside the body; Bar takes input on the whole window while this is true.
    readonly property bool popupOpen: root.page?.overlayOpen === true

    property string pageName: "home"
    property real contentHeight: root.page?.implicitHeight ?? 0

    signal closeRequested()
    signal navigateRequested(string view)

    implicitWidth: root.panelWidth
    implicitHeight: root.contentHeight + root.contentPadding * 2
    focus: true

    function openPage(name) {
        if (!(name in root.pages)) {
            console.warn("ControlPanelView: unknown page", name);
            name = "home";
        }
        root.pageName = name;
        if (root.open)
            ViewService.open("controlpanel", name === "home" ? "" : name, ViewService.monitorName);
    }

    function back() {
        if (root.page?.overlayOpen)
            root.page.closeOverlay();
        else if (root.pageName !== "home")
            root.openPage("home");
        else
            root.closeRequested();
    }

    Component.onCompleted: root.openPage(ViewService.page || "home")

    Keys.onEscapePressed: root.back()

    Behavior on contentHeight {
        Anim {
            duration: Tokens.animDuration.spatialFast
        }
    }

    Connections {
        target: ViewService

        function onPageChanged() {
            const name = ViewService.page || "home";
            if (root.open && name !== root.pageName)
                root.openPage(name);
        }
    }

    Item {
        id: pageArea

        x: root.contentPadding
        y: root.contentPadding
        width: root.width - root.contentPadding * 2
        height: root.contentHeight
        clip: true

        PageSlot {
            id: homeSlot

            width: pageArea.width
            name: "home"
            source: "HomePage.qml"
            currentPage: root.pageName
            open: root.open
            onPageRequested: name => root.openPage(name)
            onBackRequested: root.back()
            onNavigateRequested: view => root.navigateRequested(view)
        }

        PageSlot {
            id: wifiSlot

            width: pageArea.width
            name: "wifi"
            source: "WifiPage.qml"
            currentPage: root.pageName
            open: root.open
            onPageRequested: name => root.openPage(name)
            onBackRequested: root.back()
            onNavigateRequested: view => root.navigateRequested(view)
        }

        PageSlot {
            id: bluetoothSlot

            width: pageArea.width
            name: "bluetooth"
            source: "BluetoothPage.qml"
            currentPage: root.pageName
            open: root.open
            onPageRequested: name => root.openPage(name)
            onBackRequested: root.back()
            onNavigateRequested: view => root.navigateRequested(view)
        }

        PageSlot {
            id: nightLightSlot

            width: pageArea.width
            name: "nightlight"
            source: "NightLightPage.qml"
            currentPage: root.pageName
            open: root.open
            onPageRequested: name => root.openPage(name)
            onBackRequested: root.back()
            onNavigateRequested: view => root.navigateRequested(view)
        }

        PageSlot {
            id: audioSlot

            width: pageArea.width
            name: "audio"
            source: "AudioPage.qml"
            currentPage: root.pageName
            open: root.open
            onPageRequested: name => root.openPage(name)
            onBackRequested: root.back()
            onNavigateRequested: view => root.navigateRequested(view)
        }

        PageSlot {
            id: batterySlot

            width: pageArea.width
            name: "battery"
            source: "BatteryPage.qml"
            currentPage: root.pageName
            open: root.open
            onPageRequested: name => root.openPage(name)
            onBackRequested: root.back()
            onNavigateRequested: view => root.navigateRequested(view)
        }
    }
}
