import Quickshell
import Quickshell.Wayland
import QtQuick

import qs
import qs.config

Scope {
    id: root

    readonly property int borderThickness: Config.border.thickness
    readonly property int edgeReservation: Math.max(0, root.borderThickness + Config.border.gap)
    readonly property int topReservation: Tokens.bar.collapsedHeight + Config.bar.borderGap + (Config.bar.floating ? Config.bar.floatingGap : 0)

    Variants {
        model: Quickshell.screens

        Scope {
            id: screenScope

            required property var modelData

            Variants {
                model: ["top", "bottom", "left", "right"]

                PanelWindow {
                    id: edgePanel

                    required property string modelData
                    readonly property bool isHorizontalEdge: modelData === "top" || modelData === "bottom"

                    screen: screenScope.modelData

                    anchors {
                        top: modelData === "top" || !isHorizontalEdge
                        bottom: modelData === "bottom" || !isHorizontalEdge
                        left: modelData === "left" || isHorizontalEdge
                        right: modelData === "right" || isHorizontalEdge
                    }

                    implicitWidth: isHorizontalEdge ? 1 : root.edgeReservation
                    implicitHeight: isHorizontalEdge ? root.edgeReservation : 1

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