import Quickshell
import Quickshell.Wayland
import QtQuick

import qs.config

Scope {
    id: root

    readonly property int borderThickness: Config.border.thickness
    readonly property int edgeReservation: Math.max(0, root.borderThickness)
    // Border + bar + borderGap below it; a floating island also has floatingGap above it.
    readonly property int topReservation: root.edgeReservation + Config.bar.collapsedHeight + Config.bar.borderGap
        + (Config.bar.floating ? Config.bar.floatingGap : 0)

    Variants {
        model: Quickshell.screens

        Scope {
            id: screenScope

            required property var modelData

            Variants {
                model: ["top", "bottom", "left", "right"]

                PanelWindow {
                    id: zone

                    required property string modelData
                    readonly property bool horizontal: modelData === "top" || modelData === "bottom"

                    screen: screenScope.modelData

                    anchors {
                        top: modelData === "top" || !horizontal
                        bottom: modelData === "bottom" || !horizontal
                        left: modelData === "left" || horizontal
                        right: modelData === "right" || horizontal
                    }

                    implicitWidth: horizontal ? 1 : root.edgeReservation
                    implicitHeight: horizontal ? root.edgeReservation : 1

                    exclusiveZone: modelData === "top" ? root.topReservation : root.edgeReservation

                    color: "transparent"

                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "quickshell-exclusion-" + modelData

                    mask: Region {}
                }
            }
        }
    }
}