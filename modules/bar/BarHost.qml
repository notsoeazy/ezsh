import QtQuick

import qs
import qs.config
import qs.services
import qs.components

import qs.modules.osd
import qs.modules.launcher
import qs.modules.wallpaper
import qs.modules.controlpanel
import qs.modules.session

// Routes the bar body between its views: the bar itself, the OSD, and the views in `views`
// (opened through ViewService). The OSD (from OsdService) shows over an open view, which stays
// loaded underneath. A requested view loads in the background while the current one stays on
// screen; once it is ready the current one fades out, the body resizes, and the new one fades in.
// To add a view: add a ViewSlot with the view as its sourceComponent, list it in `views`, give
// the view's root implicitWidth/implicitHeight, and emit closeRequested() to go back to the bar.
Item {
    id: root

    required property string monitorName

    readonly property var views: ({
            launcher: launcherSlot,
            wallpaper: wallpaperSlot,
            controlpanel: controlPanelSlot,
            session: sessionSlot
        })
    readonly property int osdPadding: Tokens.spacing.xs
    readonly property ViewSlot displayedSlot: root.views[root.displayedView] ?? null
    readonly property real displayedWidth: root.displayedView === "bar" ? barView.implicitWidth
        : root.displayedView === "osd" ? osdView.implicitWidth + root.osdPadding * 2
        : root.displayedSlot?.item?.implicitWidth ?? 0
    readonly property real displayedHeight: root.displayedView === "bar" ? barView.implicitHeight
        : root.displayedView === "osd" ? osdView.implicitHeight + root.osdPadding * 2
        : root.displayedSlot?.item?.implicitHeight ?? 0

    readonly property bool popupOpen: root.displayedView === "bar" ? barView.popupOpen : root.displayedSlot?.item?.popupOpen === true
    readonly property bool coversOsd:root.views[root.requestedView]?.item?.coversOsd === true
    readonly property bool osdAllowed: !coversOsd && (requestedView === "bar" ? !root.barExpanded : Config.osd.showOverViews)
    readonly property bool osdBlocked: OsdService.showing && root.isFocusedMonitor && !root.osdAllowed
    readonly property bool osdLevelBlocked: root.osdBlocked && OsdService.showsLevel
    readonly property bool isFocusedMonitor: root.monitorName === HyprlandService.focusedMonitorName

    readonly property bool osdRequested: (OsdService.showing && root.isFocusedMonitor) || (root.fullscreen && root.displayedView === "osd" && !root.retracted)
    readonly property bool showsOsd: OsdService.showing && root.isFocusedMonitor && root.osdAllowed

    readonly property string targetView: osdRequested && osdAllowed ? "osd" : requestedView
    readonly property string requestedView: ViewService.view !== "" && ViewService.monitorName === root.monitorName ? ViewService.view : "bar"

    readonly property real displayedOpacity: root.displayedView === "bar" ? barView.opacity : root.displayedView === "osd" ? osdView.opacity : (root.displayedSlot?.opacity ?? 0)

    property string displayedView: "bar"
    property bool leaving: false
    property bool barExpanded: false
    property real expansionProgress: 0
    property bool fullscreen: false
    property bool retracted: false

    signal viewChangeStarting(bool animate)

    function targetReady() {
        return root.targetView === "bar" || root.targetView === "osd" || root.views[root.targetView]?.status === Loader.Ready;
    }

    function scheduleSwitch() {
        Qt.callLater(root.switchViews);
    }

    function switchViews() {
        if (root.targetView === root.displayedView || !root.targetReady()) {
            root.leaving = false;
            return;
        }
        if (root.retracted) {
            root.commit(false);
            return;
        }
        root.leaving = true;
        if (root.displayedOpacity === 0)
            root.commit(true);
    }

    function commit(animate) {
        root.leaving = false;
        root.viewChangeStarting(animate);
        root.displayedView = root.targetView;
    }

    function navigateTo(view, page) {
        if (view === "bar")
            ViewService.close()
        else
            ViewService.open(view, page ?? "", root.monitorName)
    }

    onRequestedViewChanged: {
        if (root.requestedView !== "bar" && !(root.requestedView in root.views)) {
            console.warn("BarHost: unknown view", root.requestedView)
            Qt.callLater(ViewService.close)
        }
    }
    onOsdLevelBlockedChanged: Qt.callLater(() => OsdService.setBlocked(root.osdBlocked))
    Component.onDestruction: {
        if (root.osdBlocked)
            OsdService.setBlocked(false);
    }
    onOsdBlockedChanged: {
        Qt.callLater(() => OsdService.setBlocked(root.osdBlocked));
    }
    onTargetViewChanged: root.scheduleSwitch()
    onRetractedChanged: root.scheduleSwitch()
    onDisplayedOpacityChanged: {
        if (root.leaving && root.displayedOpacity === 0)
            root.scheduleSwitch();
    }

    BarView {
        id: barView

        anchors.fill: parent

        expanded: root.barExpanded
        progress: root.expansionProgress

        opacity: root.displayedView === "bar" && !root.leaving ? 1 : 0
        visible: opacity > 0

        onNavigateRequested: (view, page) => root.navigateTo(view, page)

        Behavior on opacity {
            Anim {
                duration: Tokens.animDuration.effectsFast
            }
        }
    }

    OsdView {
        id: osdView

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        opacity: root.displayedView === "osd" && !root.leaving ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                duration: Tokens.animDuration.effectsFast
            }
        }
    }

    ViewSlot {
        id: launcherSlot

        anchors.fill: parent
        host: root
        name: "launcher"

        sourceComponent: LauncherView {
            onCloseRequested: ViewService.close()
            onNavigateRequested: view => root.navigateTo(view)
        }
    }

    ViewSlot {
        id: wallpaperSlot

        anchors.fill: parent
        host: root
        name: "wallpaper"

        sourceComponent: WallpaperView {
            onCloseRequested: ViewService.close()
        }
    }

    ViewSlot {
        id: controlPanelSlot

        anchors.fill: parent
        host: root
        name: "controlpanel"

        sourceComponent: ControlPanelView {
            onCloseRequested: ViewService.close()
            onNavigateRequested: view => root.navigateTo(view)
        }
    }

    ViewSlot {
        id: sessionSlot

        anchors.fill: parent
        host: root
        name: "session"

        sourceComponent: SessionView {
            onCloseRequested: ViewService.close()
        }
    }
}
