
import QtQuick

import qs
import qs.config
import qs.components

import "views"

Item {
    id: root

    readonly property real barContentWidth: barView.contentWidth
    readonly property real osdWidth: osdView.implicitWidth
    readonly property real osdHeight: osdView.implicitHeight
    readonly property bool coversOsd: viewLoader.item?.coversOsd === true
    readonly property bool osdAllowed: !coversOsd && (requestedView === "bar" || Config.osd.showOverViews)
    readonly property string targetView: osdRequested && osdAllowed ? "osd" : requestedView

    property string requestedView: "bar"
    property string displayedView: "bar"
    property bool barExpanded: false
    property real expansionProgress: 0
    property bool osdRequested: false
    property bool retracted: false
    property bool fadingBetweenViews: false

    signal viewChangeStarting(bool animate)

    function scheduleViewSwitch() {
        if (targetView === displayedView) {
            viewFade.stop()
            fadingBetweenViews = false
        } else if (retracted) {
            viewFade.stop()
            fadingBetweenViews = false
            Qt.callLater(showTargetView)
        } else if (!viewFade.running) {
            viewFade.restart()
        }
    }

    function showTargetView() {
        if (targetView === displayedView)
            return

        viewChangeStarting(!retracted)
        displayedView = targetView
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
            script: {
                root.fadingBetweenViews = false
                root.showTargetView()
            }
        }
    }

    function navigateTo(view) {
        requestedView = view
    }

    function goHome() {
        navigateTo("bar")
    }

    function goBack() {
        goHome()
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

        active: root.requestedView !== "bar"
        asynchronous: true

        sourceComponent: placeholderView

        opacity: root.displayedView === root.requestedView && !root.fadingBetweenViews && status === Loader.Ready ? 1 : 0
        visible: opacity > 0

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
                    switch (root.requestedView) {
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
