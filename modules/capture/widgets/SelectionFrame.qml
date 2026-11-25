import QtQuick
import QtQuick.Shapes

import qs
import qs.themes
import qs.components

// Dims the screen except for the selection, outlines it with guide rulers and shows its size.
// With no selection the hole is dimmed over where it was instead of shrinking away.
Item {
    id: root

    required property var selection
    required property real dimOpacity
    required property bool moveInstantly
    required property bool showOutline
    required property bool showSize
    required property real pixelRatio

    property rect heldSelection: Qt.rect(0, 0, root.width, root.height)
    property real holeX: root.heldSelection.x
    property real holeY: root.heldSelection.y
    property real holeWidth: root.heldSelection.width
    property real holeHeight: root.heldSelection.height
    property real animatedDimOpacity: root.dimOpacity
    property real selectionOpacity: root.hasSelection ? 1 : 0

    readonly property int outlineWidth: Tokens.stroke.thick
    readonly property real rulerOpacity: 0.35
    readonly property var rulerDashPattern: [4, 4]
    readonly property bool hasSelection: root.selection !== null

    Behavior on holeX {
        enabled: !root.moveInstantly

        Anim {
            duration: Tokens.animDuration.spatialFast
        }
    }

    Behavior on holeY {
        enabled: !root.moveInstantly

        Anim {
            duration: Tokens.animDuration.spatialFast
        }
    }

    Behavior on holeWidth {
        enabled: !root.moveInstantly

        Anim {
            duration: Tokens.animDuration.spatialFast
        }
    }

    Behavior on holeHeight {
        enabled: !root.moveInstantly

        Anim {
            duration: Tokens.animDuration.spatialFast
        }
    }

    Behavior on animatedDimOpacity {
        Anim {
            duration: Tokens.animDuration.effectsSlow
        }
    }

    Behavior on selectionOpacity {
        Anim {
            duration: Tokens.animDuration.effects
        }
    }

    Binding {
        target: root
        property: "heldSelection"
        value: root.selection
        when: root.hasSelection
        restoreMode: Binding.RestoreNone
    }

    // Four bands around the hole, so the selection shows the frozen screen untouched.
    Repeater {
        model: [
            Qt.rect(0, 0, root.width, root.holeY),
            Qt.rect(0, root.holeY + root.holeHeight, root.width, root.height - root.holeY - root.holeHeight),
            Qt.rect(0, root.holeY, root.holeX, root.holeHeight),
            Qt.rect(root.holeX + root.holeWidth, root.holeY, root.width - root.holeX - root.holeWidth, root.holeHeight)
        ]

        Rectangle {
            id: band

            required property rect modelData

            x: band.modelData.x
            y: band.modelData.y
            width: Math.max(0, band.modelData.width)
            height: Math.max(0, band.modelData.height)
            color: Qt.alpha(Theme.color.m3scrim, root.animatedDimOpacity)
        }
    }

    Rectangle {
        x: root.holeX
        y: root.holeY
        width: root.holeWidth
        height: root.holeHeight
        visible: root.selectionOpacity < 1
        color: Qt.alpha(Theme.color.m3scrim, root.animatedDimOpacity * (1 - root.selectionOpacity))
    }

    Shape {
        anchors.fill: parent
        opacity: root.showOutline ? root.selectionOpacity : 0
        visible: opacity > 0

        ShapePath {
            strokeColor: Qt.alpha(Theme.color.m3onSurface, root.rulerOpacity)
            strokeWidth: 1
            strokeStyle: ShapePath.DashLine
            dashPattern: root.rulerDashPattern
            fillColor: "transparent"
            startX: 0
            startY: root.holeY

            PathLine { x: root.width; y: root.holeY }
            PathMove { x: 0; y: root.holeY + root.holeHeight }
            PathLine { x: root.width; y: root.holeY + root.holeHeight }
            PathMove { x: root.holeX; y: 0 }
            PathLine { x: root.holeX; y: root.height }
            PathMove { x: root.holeX + root.holeWidth; y: 0 }
            PathLine { x: root.holeX + root.holeWidth; y: root.height }
        }
    }

    Rectangle {
        x: root.holeX - root.outlineWidth
        y: root.holeY - root.outlineWidth
        width: root.holeWidth + root.outlineWidth * 2
        height: root.holeHeight + root.outlineWidth * 2
        opacity: root.showOutline ? root.selectionOpacity : 0
        visible: opacity > 0
        radius: Tokens.radius.sm
        color: "transparent"
        border.width: root.outlineWidth
        border.color: Theme.color.m3primary
    }

    StyledRectangle {
        id: sizeBadge

        readonly property real gap: Tokens.spacing.xs
        readonly property bool fitsBelow: root.holeY + root.holeHeight + sizeBadge.height + sizeBadge.gap <= root.height

        x: Math.max(sizeBadge.gap, Math.min(root.holeX, root.width - sizeBadge.width - sizeBadge.gap))
        y: sizeBadge.fitsBelow ? root.holeY + root.holeHeight + sizeBadge.gap : Math.max(sizeBadge.gap, root.holeY - sizeBadge.height - sizeBadge.gap)
        implicitWidth: sizeText.implicitWidth + Tokens.spacing.sm * 2
        implicitHeight: sizeText.implicitHeight + Tokens.spacing.xs
        radius: Tokens.radius.full
        color: Theme.color.m3surfaceContainer
        opacity: root.showSize ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                duration: Tokens.animDuration.effectsFast
            }
        }

        StyledText {
            id: sizeText

            anchors.centerIn: parent
            animateFontSize: false
            text: `${Math.round(root.holeWidth * root.pixelRatio)} × ${Math.round(root.holeHeight * root.pixelRatio)}`
            font.pixelSize: Tokens.fontSize.sm
            font.features: { "tnum": 1 }
            color: Theme.color.m3onSurface
        }
    }
}
