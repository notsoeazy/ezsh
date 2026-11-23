import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes

import qs
import qs.config
import qs.themes
import qs.components
import qs.services
import qs.modules

Scope {
    id: root

    readonly property color backgroundColor: Theme.color.m3background

    readonly property int collapsedHeight: Tokens.bar.collapsedHeight

    readonly property int expandedWidth: Config.bar.expandedWidth
    readonly property int expandedHeight: Tokens.bar.expandedHeight

    readonly property int cornerRadius: Config.bar.cornerRadius

    readonly property int osdPadding: Tokens.spacing.xs

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property var modelData
            readonly property var monitor: HyprlandService.monitorFor(window.screen)
            readonly property bool fullscreen: HyprlandService.isFullscreenOn(window.monitor)
            readonly property real borderThickness: Config.border.thickness * (1 - window.fullscreenProgress)
            readonly property bool viewOpen: barHost.requestedView !== "bar"

            property real fullscreenProgress: window.fullscreen ? 1 : 0

            screen: modelData
            
            Behavior on fullscreenProgress {
                Anim {}
            }

            anchors { top: true; bottom: true; left: true; right: true }

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            WlrLayershell.layer: window.fullscreenProgress > 0 || HyprlandService.hasFullscreenUnderSpecial(window.monitor) ? WlrLayer.Overlay : WlrLayer.Top
            WlrLayershell.namespace: "quickshell-bar"
            WlrLayershell.keyboardFocus: window.viewOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            HyprlandFocusGrab {
                active: window.viewOpen
                windows: [window]
                onCleared: ViewService.close()
            }

            mask: Region { item: barBody.hideProgress < 1 ? contentLayer : null }

            Border {
                anchors.fill: parent
                thickness: window.borderThickness
                cornerRadius: Config.border.radius * (1 - window.fullscreenProgress)
            }

            Item {
                id: barBody

                anchors.top: parent.top
                x: (parent.width - width) / 2
                anchors.topMargin: restingTopMargin - hideProgress * (restingTopMargin + height)

                readonly property real restingTopMargin: window.borderThickness + (Config.bar.floating ? Config.bar.floatingGap : 0)
                readonly property bool isFloating: Config.bar.floating
                readonly property bool expanded: hoverHandler.hovered && barHost.displayedView === "bar" && !window.fullscreen

                property real hideProgress: window.fullscreen && !barHost.showsOsd && !window.viewOpen ? 1 : 0
                property real progress: expanded ? 1 : 0
                property real previousWidth: 0
                property real previousHeight: 0
                property real resizeProgress: 1

                Behavior on hideProgress {
                    Anim {}
                }

                Behavior on progress {
                    Anim {}
                }

                Connections {
                    target: barHost

                    function onViewChangeStarting(animate) {
                        resizeAnim.stop()
                        barBody.previousWidth = barBody.bodyWidth
                        barBody.previousHeight = barBody.bodyHeight
                        barBody.resizeProgress = animate ? 0 : 1
                        if (animate) resizeAnim.restart()
                    }
                }

                Anim {
                    id: resizeAnim

                    target: barBody
                    property: "resizeProgress"
                    from: 0
                    to: 1
                }

                readonly property real targetWidth: {
                    switch (barHost.displayedView) {
                    case "osd":
                        return barHost.osdWidth + root.osdPadding * 2
                    case "bar":
                        return barHost.barContentWidth
                            + (Math.max(root.expandedWidth, barHost.barContentWidth) - barHost.barContentWidth) * progress
                    default:
                        return barHost.viewWidth
                    }
                }

                readonly property real targetHeight: {
                    switch (barHost.displayedView) {
                        case "osd":
                            return barHost.osdHeight + root.osdPadding * 2
                        case "bar":
                            return root.collapsedHeight + (root.expandedHeight - root.collapsedHeight) * progress
                        default:
                            return barHost.viewHeight
                    }
                }

                readonly property real bodyWidth: previousWidth + (targetWidth - previousWidth) * resizeProgress
                readonly property real bodyHeight: previousHeight + (targetHeight - previousHeight) * resizeProgress
                readonly property real radius: Math.min(isFloating ? root.collapsedHeight / 2 : root.cornerRadius, bodyWidth / 2)
                readonly property real radiusY: Math.min(radius, bodyHeight / 2)
                readonly property real shoulderRadiusX: Math.max(0.01, radius * Math.abs(cornerFlip))
                readonly property real shoulderRadiusY: Math.max(0.01, radiusY * Math.abs(cornerFlip))
                readonly property int cornerSweep: cornerFlip >= 0 ? PathArc.Clockwise : PathArc.Counterclockwise

                property real cornerFlip: isFloating ? -1 : 1

                Behavior on cornerFlip {
                    Anim {}
                }

                width: bodyWidth + radius * 2
                height: bodyHeight

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        fillColor: root.backgroundColor
                        strokeWidth: -1

                        startX: barBody.radius * (1 - barBody.cornerFlip)
                        startY: 0

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
