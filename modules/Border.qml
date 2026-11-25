import QtQuick
import QtQuick.Shapes

import qs.config
import qs.themes

Shape {
    id: root

    // Keep this 0, bar handles the thickness for animation
    property real thickness: 0
    property real cornerRadius: 0

    readonly property real clampedThickness: Math.min(root.thickness, root.width / 2, root.height / 2)
    readonly property real innerRadius: Math.max(0, Math.min(root.cornerRadius, (root.width - 2 * root.clampedThickness) / 2, (root.height - 2 * root.clampedThickness) / 2))

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
            x: root.clampedThickness
            y: root.clampedThickness
            width: root.width - 2 * root.clampedThickness
            height: root.height - 2 * root.clampedThickness
            radius: root.innerRadius
        }
    }
}
