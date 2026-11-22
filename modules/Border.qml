import QtQuick
import QtQuick.Shapes

import qs.themes

// The screen frame: a filled ring `thickness` wide with rounded inner corners. Drawn inside the
// bar's window so the bar and the frame share one fullscreen animation (thickness and radius
// shrink to 0, sliding the frame out to the screen edges).
Shape {
    id: root

    property real thickness: 0
    property real radius: 0

    readonly property real inset: Math.min(root.thickness, root.width / 2, root.height / 2)
    readonly property real innerRadius: Math.max(0, Math.min(root.radius, (root.width - 2 * root.inset) / 2, (root.height - 2 * root.inset) / 2))

    visible: root.thickness > 0
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: Theme.color.m3background
        fillRule: ShapePath.OddEvenFill
        strokeWidth: -1

        PathRectangle {
            width: root.width
            height: root.height
        }

        PathRectangle {
            x: root.inset
            y: root.inset
            width: root.width - 2 * root.inset
            height: root.height - 2 * root.inset
            radius: root.innerRadius
        }
    }
}
