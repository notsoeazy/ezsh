import QtQuick
import Quickshell
import Quickshell.Wayland

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

                    readonly property bool isHorizontalEdge: edgePanel.modelData === "top" || edgePanel.modelData === "bottom"

                    screen: screenScope.modelData

                    anchors {
                        top: edgePanel.modelData === "top" || !edgePanel.isHorizontalEdge
                        bottom: edgePanel.modelData === "bottom" || !edgePanel.isHorizontalEdge
                        left: edgePanel.modelData === "left" || edgePanel.isHorizontalEdge
                        right: edgePanel.modelData === "right" || edgePanel.isHorizontalEdge
                    }

                    implicitWidth: edgePanel.isHorizontalEdge ? 1 : root.edgeReservation
                    implicitHeight: edgePanel.isHorizontalEdge ? root.edgeReservation : 1

                    exclusiveZone: edgePanel.modelData === "top" ? root.topReservation : root.edgeReservation

                    color: "transparent"

                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "quickshell-exclusion-" + edgePanel.modelData

                    mask: Region {}
                }
            }
        }
    }
}
