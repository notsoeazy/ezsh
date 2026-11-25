import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs
import qs.config
import qs.themes
import qs.services
import qs.components
import qs.modules

Scope {
    id: root

    readonly property color backgroundColor: Theme.color.m3background
    readonly property int collapsedHeight: Tokens.bar.collapsedHeight
    readonly property int cornerRadius: Config.bar.cornerRadius

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property var modelData

            property real fullscreenProgress: window.fullscreen ? 1 : 0

            readonly property var monitor: HyprlandService.monitorFor(window.screen)
            readonly property bool fullscreen: HyprlandService.isFullscreenOn(window.monitor)
            readonly property real borderThickness: Config.border.thickness * (1 - window.fullscreenProgress)
            readonly property bool viewOpen: barHost.requestedView !== "bar"

            screen: window.modelData
            anchors { top: true; bottom: true; left: true; right: true }

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            WlrLayershell.layer: window.fullscreenProgress > 0 || HyprlandService.hasFullscreenUnderSpecial(window.monitor) ? WlrLayer.Overlay : WlrLayer.Top
            WlrLayershell.namespace: "quickshell-bar"
            WlrLayershell.keyboardFocus: window.viewOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            mask: barHost.popupOpen ? null : bodyRegion

            Behavior on fullscreenProgress {
                Anim {}
            }

            HyprlandFocusGrab {
                active: window.viewOpen
                windows: [window]
                onCleared: ViewService.close()
            }

            // One per screen; any of them keeps the session awake.
            IdleInhibitor {
                window: window
                enabled: KeepAwakeService.enabled
            }

            Region {
                id: bodyRegion

                item: barBody.hideProgress < 1 ? contentLayer : null
            }

            Border {
                anchors.fill: parent
                thickness: window.borderThickness
                cornerRadius: Config.border.radius * (1 - window.fullscreenProgress)
            }

            Item {
                id: barBody

                property bool hovered: false
                property bool hoverBlocked: false

                property real hideProgress: window.fullscreen && !barHost.showsOsd && !window.viewOpen ? 1 : 0
                property real progress: barBody.expanded ? 1 : 0
                property real previousWidth: 0
                property real previousHeight: 0
                property real resizeProgress: 1
                property real cornerFlip: barBody.isFloating ? -1 : 1

                readonly property bool isFloating: Config.bar.floating
                readonly property real restingTopMargin: window.borderThickness + (barBody.isFloating ? Config.bar.floatingGap : 0)
                // A tray menu sits outside the body, so it keeps the bar open while the pointer is on it.
                readonly property bool expanded: (barBody.hovered || barHost.popupOpen) && barHost.displayedView === "bar" && !window.fullscreen
                readonly property real bodyWidth: barBody.previousWidth + (barHost.displayedWidth - barBody.previousWidth) * barBody.resizeProgress
                readonly property real bodyHeight: barBody.previousHeight + (barHost.displayedHeight - barBody.previousHeight) * barBody.resizeProgress
                readonly property real radius: Math.min(barBody.isFloating ? root.collapsedHeight / 2 : root.cornerRadius, barBody.bodyWidth / 2)
                readonly property real radiusY: Math.min(barBody.radius, barBody.bodyHeight / 2)
                readonly property real shoulderRadiusX: Math.max(0.01, barBody.radius * Math.abs(barBody.cornerFlip))
                readonly property real shoulderRadiusY: Math.max(0.01, barBody.radiusY * Math.abs(barBody.cornerFlip))
                readonly property int cornerSweep: barBody.cornerFlip >= 0 ? PathArc.Clockwise : PathArc.Counterclockwise

                anchors.top: parent.top
                anchors.topMargin: barBody.restingTopMargin - barBody.hideProgress * (barBody.restingTopMargin + barBody.height)
                x: (parent.width - barBody.width) / 2
                width: barBody.bodyWidth + barBody.radius * 2
                height: barBody.bodyHeight

                Behavior on hideProgress {
                    Anim {}
                }

                Behavior on progress {
                    Anim {}
                }

                Behavior on cornerFlip {
                    Anim {}
                }

                Connections {
                    target: barHost

                    function onViewChangeStarting(animate) {
                        enterTimer.stop();
                        exitTimer.stop();
                        barBody.hovered = false;
                        barBody.hoverBlocked = hoverHandler.hovered;
                        resizeAnim.stop();
                        barBody.previousWidth = barBody.bodyWidth;
                        barBody.previousHeight = barBody.bodyHeight;
                        barBody.resizeProgress = animate ? 0 : 1;
                        if (animate)
                            resizeAnim.restart();
                    }
                }

                Anim {
                    id: resizeAnim

                    target: barBody
                    property: "resizeProgress"
                    from: 0
                    to: 1
                }

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        fillColor: root.backgroundColor
                        strokeWidth: -1
                        startX: barBody.radius * (1 - barBody.cornerFlip)
                        startY: 0

                        Behavior on fillColor {
                            CAnim {}
                        }

                        PathArc {
                            relativeX: barBody.radius * barBody.cornerFlip
                            relativeY: barBody.shoulderRadiusY
                            radiusX: barBody.shoulderRadiusX
                            radiusY: barBody.shoulderRadiusY
                            direction: barBody.cornerSweep
                        }

                        PathLine {
                            relativeX: 0
                            relativeY: barBody.bodyHeight - barBody.radiusY - barBody.shoulderRadiusY
                        }

                        PathArc {
                            relativeX: barBody.radius
                            relativeY: barBody.radiusY
                            radiusX: barBody.radius
                            radiusY: barBody.radiusY
                            direction: PathArc.Counterclockwise
                        }

                        PathLine {
                            relativeX: barBody.bodyWidth - barBody.radius * 2
                            relativeY: 0
                        }

                        PathArc {
                            relativeX: barBody.radius
                            relativeY: -barBody.radiusY
                            radiusX: barBody.radius
                            radiusY: barBody.radiusY
                            direction: PathArc.Counterclockwise
                        }

                        PathLine {
                            relativeX: 0
                            relativeY: -(barBody.bodyHeight - barBody.radiusY - barBody.shoulderRadiusY)
                        }

                        PathArc {
                            relativeX: barBody.radius * barBody.cornerFlip
                            relativeY: -barBody.shoulderRadiusY
                            radiusX: barBody.shoulderRadiusX
                            radiusY: barBody.shoulderRadiusY
                            direction: barBody.cornerSweep
                        }
                    }
                }

                HoverHandler {
                    id: hoverHandler

                    onHoveredChanged: {
                        if (hoverHandler.hovered) {
                            exitTimer.stop();
                            if (!barBody.hoverBlocked)
                                enterTimer.restart();
                        } else {
                            enterTimer.stop();
                            barBody.hoverBlocked = false;
                            exitTimer.restart();
                        }
                    }
                }

                Timer {
                    id: enterTimer

                    interval: Config.bar.hoverEnterDelay
                    onTriggered: barBody.hovered = true
                }

                Timer {
                    id: exitTimer

                    interval: Config.bar.hoverExitDelay
                    onTriggered: barBody.hovered = false
                }

                Item {
                    id: contentLayer

                    x: barBody.radius
                    width: barBody.bodyWidth
                    height: barBody.bodyHeight
                    clip: true

                    BarHost {
                        id: barHost

                        anchors.fill: parent
                        monitorName: window.monitor?.name ?? ""
                        barExpanded: barBody.expanded
                        expansionProgress: barBody.progress
                        fullscreen: window.fullscreen
                        retracted: barBody.hideProgress >= 1
                    }
                }
            }
        }
    }
}
