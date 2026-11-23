import QtQuick

import qs
import qs.config
import qs.services
import qs.components

import qs.modules.osd
import qs.modules.launcher

// Routes the bar body between its views: the bar itself, the OSD, and the views in `views`
// (opened through ViewService). The OSD (from OsdService) shows over an open view, which stays
// loaded underneath. Switching fades the old view out, resizes the body, then fades the new
// one in. To add a view: add a Component to `views`, give its root
// implicitWidth/implicitHeight, and emit closeRequested() to go back to the bar.
Item {
    id: root

    required property string monitorName

    readonly property var views: ({
            launcher: launcherView
        })
    readonly property real barContentWidth: barView.contentWidth
    readonly property real osdWidth: osdView.implicitWidth
    readonly property real osdHeight: osdView.implicitHeight

    readonly property real viewWidth: viewLoader.item?.implicitWidth ?? 0
    readonly property real viewHeight: viewLoader.item?.implicitHeight ?? 0

    readonly property bool coversOsd: viewLoader.item?.coversOsd === true
    readonly property bool osdAllowed: !coversOsd && (requestedView === "bar" || Config.osd.showOverViews)
    readonly property bool isFocusedMonitor: root.monitorName === HyprlandService.focusedMonitorName

    readonly property bool osdRequested: (OsdService.showing && root.isFocusedMonitor) || (root.fullscreen && root.displayedView === "osd" && !root.retracted)
    readonly property bool showsOsd: OsdService.showing && root.isFocusedMonitor && root.osdAllowed

    readonly property string targetView: osdRequested && osdAllowed ? "osd" : requestedView
    readonly property string requestedView: ViewService.view !== "" && ViewService.monitorName === root.monitorName ? ViewService.view : "bar"

    property string displayedView: "bar"
    // The view the loader holds; kept while it fades out after closing.
    property string loadedView: ""
    property bool barExpanded: false
    property real expansionProgress: 0
    property bool fullscreen: false
    property bool retracted: false
    property bool fadingBetweenViews: false

    signal viewChangeStarting(bool animate)

    function targetReady() {
        return targetView === "bar" || targetView === "osd" || (viewLoader.status === Loader.Ready && root.loadedView === targetView)
    }

    function scheduleViewSwitch() {
        if (targetView === displayedView) {
            viewFade.stop()
            fadingBetweenViews = false
            if (displayedView === "bar")
                loadedView = ""
        } else if (retracted) {
            viewFade.stop()
            fadingBetweenViews = false
            Qt.callLater(showTargetView)
        } else if (!viewFade.running) {
            viewFade.restart()
        }
    }

    function showTargetView() {
        if (targetView === displayedView || !targetReady())
            return

        fadingBetweenViews = false
        viewChangeStarting(!retracted)
        displayedView = targetView
        if (displayedView === "bar")
            loadedView = ""
    }

    function navigateTo(view) {
        if (view === "bar")
            ViewService.close()
        else
            ViewService.open(view, "", root.monitorName)
    }

    onRequestedViewChanged: {
        if (requestedView === "bar")
            return
        if (!(requestedView in views)) {
            console.warn("BarHost: unknown view", requestedView)
            Qt.callLater(ViewService.close)
            return
        }
        loadedView = requestedView
    }
    onTargetViewChanged: scheduleViewSwitch()
    onRetractedChanged: scheduleViewSwitch()

    SequentialAnimation {
        id: viewFade

        ScriptAction {
            script: root.fadingBetweenViews = true
        }
        PauseAnimation {
            duration: Tokens.animDuration.effectsFast
        }
        ScriptAction {
            script: root.showTargetView()
        }
    }

    BarView {
        id: barView

        anchors.fill: parent

        expanded: root.barExpanded
        progress: root.expansionProgress

        opacity: root.displayedView === "bar" && !root.fadingBetweenViews ? 1 : 0
        visible: opacity > 0

        onNavigateRequested: view => root.navigateTo(view)

        Behavior on opacity {
            Anim {
                duration: Tokens.animDuration.effectsFast
            }
        }
    }

    Loader {
        id: viewLoader

        anchors.fill: parent

        active: root.loadedView !== ""
        asynchronous: true

        sourceComponent: root.views[root.loadedView] ?? null

        opacity: root.displayedView === root.requestedView && root.displayedView === root.loadedView && !root.fadingBetweenViews && status === Loader.Ready ? 1 : 0
        visible: opacity > 0

        onLoaded: {
            if (!viewFade.running)
                root.showTargetView()
        }

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

        opacity: root.displayedView === "osd" && !root.fadingBetweenViews ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                duration: Tokens.animDuration.effectsFast
            }
        }
    }

    Component {
        id: launcherView

        LauncherView {
            onCloseRequested: ViewService.close()
        }
    }
}
