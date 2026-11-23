import QtQuick

import qs
import qs.config
import qs.services
import qs.components

import qs.modules.osd
import qs.modules.launcher
import qs.modules.wallpaper

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
            wallpaper: wallpaperSlot
        })
    readonly property real barContentWidth: barView.contentWidth
    readonly property real osdWidth: osdView.implicitWidth
    readonly property real osdHeight: osdView.implicitHeight

    // The displayed view's size; its slot stays loaded until it has faded out, so Bar resizes from it.
    readonly property ViewSlot displayedSlot: root.views[root.displayedView] ?? null
    readonly property real viewWidth: root.displayedSlot?.item?.implicitWidth ?? 0
    readonly property real viewHeight: root.displayedSlot?.item?.implicitHeight ?? 0

    readonly property bool coversOsd: root.views[root.requestedView]?.item?.coversOsd === true
    readonly property bool osdAllowed: !coversOsd && (requestedView === "bar" || Config.osd.showOverViews)
    readonly property bool isFocusedMonitor: root.monitorName === HyprlandService.focusedMonitorName

    readonly property bool osdRequested: (OsdService.showing && root.isFocusedMonitor) || (root.fullscreen && root.displayedView === "osd" && !root.retracted)
    readonly property bool showsOsd: OsdService.showing && root.isFocusedMonitor && root.osdAllowed

    readonly property string targetView: osdRequested && osdAllowed ? "osd" : requestedView
    readonly property string requestedView: ViewService.view !== "" && ViewService.monitorName === root.monitorName ? ViewService.view : "bar"

    // Opacity of whatever is displayed now; the switch commits when it reaches 0.
    readonly property real displayedOpacity: root.displayedView === "bar" ? barView.opacity : root.displayedView === "osd" ? osdView.opacity : (root.displayedSlot?.opacity ?? 0)

    property string displayedView: "bar"
    // The displayed layer is fading out so the target can take over.
    property bool leaving: false
    property bool barExpanded: false
    property real expansionProgress: 0
    property bool fullscreen: false
    property bool retracted: false

    signal viewChangeStarting(bool animate)

    function targetReady() {
        return root.targetView === "bar" || root.targetView === "osd" || root.views[root.targetView]?.status === Loader.Ready;
    }

    // Called (through scheduleSwitch) whenever the target, readiness, retraction or the displayed
    // layer's opacity changes: keeps the current layer on screen until the target is loaded, then
    // fades it out and commits once it has reached 0.
    function scheduleSwitch() {
        // Deferred: committing changes displayedView, which the triggering bindings depend on.
        Qt.callLater(root.switchViews);
    }

    function switchViews() {
        if (root.targetView === root.displayedView || !root.targetReady()) {
            root.leaving = false;
            return;
        }
        if (root.retracted) {
            // Nothing is on screen to fade out.
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

    function navigateTo(view) {
        if (view === "bar")
            ViewService.close()
        else
            ViewService.open(view, "", root.monitorName)
    }

    onRequestedViewChanged: {
        if (requestedView !== "bar" && !(requestedView in views)) {
            console.warn("BarHost: unknown view", requestedView)
            Qt.callLater(ViewService.close)
        }
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

        onNavigateRequested: view => root.navigateTo(view)

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
}
