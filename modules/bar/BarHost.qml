
import QtQuick

import qs
import qs.config
import qs.components

import "views"

Item {
    id: root

    // Where navigation is; `shownView` is what is drawn, which is "osd" while the OSD is up.
    property string currentView: "bar"
    property string shownView: "bar"
    property bool barExpanded: false
    property real barProgress: 0
    // The OSD wants to show on this bar's screen; whether it may is decided here.
    property bool osdRequested: false
    readonly property real barContentWidth: barView.contentWidth
    readonly property real osdWidth: osdView.implicitWidth

    // The bar is out of sight (tucked above a fullscreen window): views swap at once.
    property bool hidden: false

    // A view that already shows these controls (the control panel) sets `coversOsd` and hides the OSD.
    readonly property bool coversOsd: viewLoader.item?.coversOsd === true
    readonly property bool osdAllowed: !coversOsd && (currentView === "bar" || Config.osd.overViews)
    readonly property string wantedView: osdRequested && osdAllowed ? "osd" : currentView

    // True while the old view fades out; the bar holds its size until the swap.
    property bool switching: false

    // Emitted just before shownView changes, so Bar.qml can animate the size jump;
    // `animate` is false when the bar is out of sight and should take the new size at once.
    signal viewChanging(bool animate)

    // Old view fades out, then the swap: the bar resizes while the new view fades in.
    function switchView() {
        if (wantedView === shownView) {
            viewSwitch.stop()
            switching = false
        } else if (hidden) {
            viewSwitch.stop()
            switching = false
            // Deferred: committing changes inputs of the binding that triggered this.
            Qt.callLater(commitIfWanted)
        } else if (!viewSwitch.running) {
            viewSwitch.restart()
        }
    }

    function commitIfWanted() {
        if (wantedView === shownView)
            return

        viewChanging(!hidden)
        shownView = wantedView
    }

    onWantedViewChanged: switchView()
    onHiddenChanged: switchView()

    SequentialAnimation {
        id: viewSwitch

        ScriptAction {
            script: root.switching = true
        }
        PauseAnimation {
            duration: Tokens.animDuration.effectsFast
        }
        ScriptAction {
            // Picks up the latest wanted view if it changed during the fade.
            script: {
                root.switching = false
                root.commitIfWanted()
            }
        }
    }

    // Navigation API
    function navigate(view) {
        currentView = view
    }

    function goHome() {
        navigate("bar")
    }

    function goBack() {
        goHome()
    }

    // The normal Bar remains instantiated.
    BarView {
        id: barView

        anchors.fill: parent

        expanded: root.barExpanded
        progress: root.barProgress

        opacity: root.shownView === "bar" && !root.switching ? 1 : 0
        visible: opacity > 0

        onNavigateRequested: view => root.navigate(view)

        Behavior on opacity {
            Anim {
                duration: Tokens.animDuration.effectsFast
            }
        }
    }

    // Secondary views are loaded on demand.
    Loader {
        id: viewLoader

        anchors.fill: parent

        active: root.currentView !== "bar"
        asynchronous: true

        sourceComponent: placeholderView

        opacity: root.shownView === root.currentView && !root.switching && status === Loader.Ready ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                duration: Tokens.animDuration.effectsFast
            }
        }
    }

    OsdView {
        id: osdView

        anchors.centerIn: parent

        opacity: root.shownView === "osd" && !root.switching ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                duration: Tokens.animDuration.effectsFast
            }
        }
    }

    // Temporary view used to test navigation.
    // We'll replace this with real view components.
    Component {
        id: placeholderView

        Item {
            id: placeholder

            Text {
                anchors {
                    top: parent.top
                    left: parent.left
                    margins: 24
                }

                text: {
                    switch (root.currentView) {
                    case "launcher":
                        return "Launcher"
                    case "wallpaper":
                        return "Wallpaper Selector"
                    case "theme":
                        return "Theme Selector"
                    default:
                        return "Unknown View"
                    }
                }

                color: "#ffffff"
                font.pixelSize: 20
                font.weight: Font.DemiBold
            }

            Rectangle {
                width: 90
                height: 34

                anchors {
                    right: parent.right
                    top: parent.top
                    margins: 20
                }

                radius: 10
                color: "#39414d"

                Text {
                    anchors.centerIn: parent
                    text: "Back"
                    color: "#ffffff"
                    font.pixelSize: 13
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: root.goBack()
                }
            }

            Text {
                anchors.centerIn: parent

                text: "View content coming soon"
                color: "#9ca8b8"
                font.pixelSize: 14
            }
        }
    }
}
