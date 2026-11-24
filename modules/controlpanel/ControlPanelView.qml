import QtQuick

import qs
import qs.services
import qs.components

Item {
    id: root

    readonly property int panelWidth: 440
    readonly property int contentPadding: Tokens.spacing.md
    // Each page is loaded only while shown (PageSlot).
    readonly property var pageFiles: ({
            home: "HomePage.qml",
            wifi: "WifiPage.qml",
            bluetooth: "BluetoothPage.qml",
            nightlight: "NightLightPage.qml",
            audio: "AudioPage.qml",
            battery: "BatteryPage.qml"
        })
    readonly property var pageNames: Object.keys(root.pageFiles)
    // From children, not Repeater.itemAt(): itemAt isn't a dependency, and countChanged can come before the slot exists.
    readonly property PanelPage page: Array.from(pageArea.children).find(slot => slot.name === root.pageName)?.item ?? null
    readonly property bool open: ViewService.view === "controlpanel"
    // Its sliders change the levels the OSD shows; the OSD would cover the panel.
    readonly property bool coversOsd: true
    // A Menu hangs outside the body; Bar takes input on the whole window while this is true.
    readonly property bool popupOpen: root.page?.overlayOpen === true

    // ViewService.page while open, kept while the panel fades out so the page doesn't change under it.
    property string pageName: "home"
    property real contentHeight: root.page?.implicitHeight ?? 0

    signal closeRequested()
    signal navigateRequested(string view)

    implicitWidth: root.panelWidth
    implicitHeight: root.contentHeight + root.contentPadding * 2
    focus: true

    function openPage(name) {
        if (root.open)
            ViewService.open("controlpanel", name === "home" ? "" : name, ViewService.monitorName);
    }

    function pageFor(name) {
        if (name && !(name in root.pageFiles))
            console.warn("ControlPanelView: unknown page", name);
        return name in root.pageFiles ? name : "home";
    }

    function back() {
        if (root.page?.overlayOpen)
            root.page.closeOverlay();
        else if (root.pageName !== "home")
            root.openPage("home");
        else
            root.closeRequested();
    }

    Keys.onEscapePressed: root.back()

    Behavior on contentHeight {
        Anim {
            duration: Tokens.animDuration.spatialFast
        }
    }

    Binding {
        when: root.open
        target: root
        property: "pageName"
        value: root.pageFor(ViewService.page)
        restoreMode: Binding.RestoreNone
    }

    Item {
        id: pageArea

        x: root.contentPadding
        y: root.contentPadding
        width: root.width - root.contentPadding * 2
        height: root.contentHeight
        clip: true

        Repeater {
            model: root.pageNames

            PageSlot {
                required property string modelData

                width: pageArea.width
                name: modelData
                source: root.pageFiles[modelData]
                currentPage: root.pageName
                open: root.open
                onPageRequested: name => root.openPage(name)
                onBackRequested: root.back()
                onNavigateRequested: view => root.navigateRequested(view)
            }
        }
    }
}
