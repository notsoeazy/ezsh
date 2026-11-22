import Quickshell
import Quickshell.Wayland
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

    // Matches the Border so the bar reads as part of the frame.
    readonly property color backgroundColor: Theme.color.m3background

    readonly property int collapsedHeight: Config.bar.collapsedHeight

    readonly property int expandedWidth: Config.bar.expandedWidth
    readonly property int expandedHeight: Config.bar.expandedHeight

    readonly property int launcherWidth: 620
    readonly property int launcherHeight: 380

    readonly property int wallpaperWidth: 680
    readonly property int wallpaperHeight: 420

    readonly property int themeWidth: 560
    readonly property int themeHeight: 340

    readonly property int cornerRadius: Config.bar.cornerRadius

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property var modelData
            screen: modelData

            readonly property var monitor: HyprlandService.monitorFor(window.screen)
            readonly property bool focused: window.monitor?.name === HyprlandService.focusedMonitor
            readonly property bool fullscreen: HyprlandService.fullscreenOn(window.monitor)

            // 0..1 into fullscreen: the frame thins to nothing toward the screen edges and the
            // bar rides its inner edge. One value for frame and bar, so they never drift apart.
            property real fsProgress: window.fullscreen ? 1 : 0

            Behavior on fsProgress {
                Anim {}
            }

            readonly property real borderThickness: Config.border.thickness * (1 - window.fsProgress)

            // One window for the frame and the bar, as in caelestia.
            anchors { top: true; bottom: true; left: true; right: true }

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            // Above fullscreen windows only while that is needed: the frame's exit animation, and the OSD.
            WlrLayershell.layer: window.fsProgress > 0 ? WlrLayer.Overlay : WlrLayer.Top
            WlrLayershell.namespace: "quickshell-bar"

            // Only the bar's body receives input, not the frame or the empty corner margins beside an
            // island, and nothing while the bar is tucked away above a fullscreen window.
            mask: Region { item: surface.retract < 1 ? contentLayer : null }

            Border {
                anchors.fill: parent
                thickness: window.borderThickness
                radius: Config.border.radius * (1 - window.fsProgress)
            }

            Item {
                id: surface

                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                }

                // A notch hangs from the frame's inner edge (the screen edge in fullscreen); an island
                // floats floatingGap below it. Retracting slides the bar up past the screen's top edge.
                readonly property real restTop: window.borderThickness + (Config.bar.floating ? Config.bar.floatingGap : 0)
                anchors.topMargin: restTop - retract * (restTop + height)

                readonly property bool island: Config.bar.floating

                // The OSD wants this screen (focused monitor) and may show over what is open.
                readonly property bool osdWanted: OsdService.active && window.focused && host.osdAllowed

                // 0 shown .. 1 tucked above the screen. Fullscreen tucks the bar away; the OSD drops
                // down from above and goes back up when done.
                property real retract: window.fullscreen && !osdWanted ? 1 : 0

                Behavior on retract {
                    Anim {}
                }

                readonly property bool expanded:
                    hover.hovered &&
                    host.shownView === "bar" &&
                    !window.fullscreen

                // The one clock for expand/collapse: the bar view's shape and its content both follow it,
                // so width, height and content always move together.
                property real progress: expanded ? 1 : 0

                Behavior on progress {
                    Anim {}
                }

                // Switching views blends from the size at the moment of the switch to the new view's
                // target, even while that target moves (the bar view follows `progress`). A Behavior
                // would restart on every frame of a moving target and stall.
                property real fromWidth: 0
                property real fromHeight: 0
                property real blend: 1

                Connections {
                    target: host

                    function onViewChanging(animate) {
                        blendAnim.stop()
                        surface.fromWidth = surface.bodyWidth
                        surface.fromHeight = surface.bodyHeight
                        // Out of sight (tucked above a fullscreen window): take the new size at once,
                        // so the OSD drops in at its own size instead of shrinking from the bar's.
                        surface.blend = animate ? 0 : 1
                        if (animate)
                            blendAnim.restart()
                    }
                }

                Anim {
                    id: blendAnim

                    target: surface
                    property: "blend"
                    from: 0
                    to: 1
                }

                // The view selects its preferred dimensions.
                readonly property real targetWidth: {
                    switch (host.shownView) {
                    case "osd":
                        return host.osdWidth + Tokens.spacing.md * 2
                    case "launcher":
                        return root.launcherWidth
                    case "wallpaper":
                        return root.wallpaperWidth
                    case "theme":
                        return root.themeWidth
                    default:
                        // Sized by content; expanded keeps a minimum so its hidden rows have room.
                        // Content width already animates smoothly, so no Behavior is needed here.
                        return host.barContentWidth
                            + (Math.max(root.expandedWidth, host.barContentWidth) - host.barContentWidth) * progress
                    }
                }

                readonly property real targetHeight: {
                    switch (host.shownView) {
                    case "osd":
                        return root.collapsedHeight
                    case "launcher":
                        return root.launcherHeight
                    case "wallpaper":
                        return root.wallpaperHeight
                    case "theme":
                        return root.themeHeight
                    default:
                        return root.collapsedHeight
                            + (root.expandedHeight - root.collapsedHeight) * progress
                    }
                }

                readonly property real bodyWidth: fromWidth + (targetWidth - fromWidth) * blend
                readonly property real bodyHeight: fromHeight + (targetHeight - fromHeight) * blend
                // 1: top corners curve outward into the border (notch). -1: they round inward (island).
                property real shoulder: island ? -1 : 1

                // An island is a pill at its collapsed height.
                readonly property real radius: Math.min(island ? root.collapsedHeight / 2 : root.cornerRadius, bodyWidth / 2)

                readonly property real radiusY: Math.min(radius, bodyHeight / 2)

                readonly property real cornerX: Math.max(0.01, radius * Math.abs(shoulder))

                readonly property real cornerY: Math.max(0.01, radiusY * Math.abs(shoulder))

                readonly property int cornerSweep: shoulder >= 0 ? PathArc.Clockwise : PathArc.Counterclockwise

                width: bodyWidth + radius * 2
                height: bodyHeight

                // The morphing surface.
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        fillColor: root.backgroundColor
                        strokeWidth: -1

                        startX: surface.radius * (1 - surface.shoulder)
                        startY: 0

                        PathArc {
                            relativeX: surface.radius * surface.shoulder
                            relativeY: surface.cornerY
                            radiusX: surface.cornerX
                            radiusY: surface.cornerY
                            direction: surface.cornerSweep
                        }

                        PathLine {
                            relativeX: 0
                            relativeY: surface.bodyHeight - surface.radiusY - surface.cornerY
                        }

                        PathArc {
                            relativeX: surface.radius
                            relativeY: surface.radiusY
                            radiusX: surface.radius
                            radiusY: surface.radiusY
                            direction: PathArc.Counterclockwise
                        }

                        PathLine {
                            relativeX: surface.bodyWidth - surface.radius * 2
                            relativeY: 0
                        }

                        PathArc {
                            relativeX: surface.radius
                            relativeY: -surface.radiusY
                            radiusX: surface.radius
                            radiusY: surface.radiusY
                            direction: PathArc.Counterclockwise
                        }

                        PathLine {
                            relativeX: 0
                            relativeY: -(surface.bodyHeight - surface.radiusY - surface.cornerY)
                        }

                        PathArc {
                            relativeX: surface.radius * surface.shoulder
                            relativeY: -surface.cornerY
                            radiusX: surface.cornerX
                            radiusY: surface.cornerY
                            direction: surface.cornerSweep
                        }
                    }
                }

                // Watches the entire Bar for hover.
                HoverHandler {
                    id: hover
                }

                // Visual content sits inside the body.
                Item {
                    id: contentLayer

                    x: surface.radius
                    width: surface.bodyWidth
                    height: surface.bodyHeight

                    clip: true

                    BarHost {
                        id: host

                        anchors.fill: parent
                        barExpanded: surface.expanded
                        barProgress: surface.progress
                        // Keep the OSD in the bar while it slides away above a fullscreen window,
                        // so the bar view never shows on the way out.
                        osdRequested: (OsdService.active && window.focused)
                            || (window.fullscreen && host.shownView === "osd" && surface.retract < 1)
                        // Fully tucked away: views can swap at once, nobody sees it.
                        hidden: surface.retract >= 1
                    }
                }

                Behavior on shoulder {
                    Anim {}
                }
            }
        }
    }
}
