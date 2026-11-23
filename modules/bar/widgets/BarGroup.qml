import QtQuick

import qs

// One bar column with two rows. The primary row is always shown: centered in
// the collapsed bar, it slides into the two-row stack when expanded. The
// secondary row only fades/slides in once expanded. Expanded, the stack as a
// whole is vertically centered in the bar.
Item {
    id: root

    property Component primaryComponent
    property Component secondaryComponent
    // Center column keeps its primary (the clock) on top; sides keep theirs on the bottom.
    property bool primaryOnTop: false
    property int alignment: Qt.AlignLeft // AlignLeft | AlignHCenter | AlignRight
    property real expansionProgress: 0 // 0 collapsed .. 1 expanded
    property bool expanded: false // target state; expansionProgress is the animated value
    // Fixed row height so rows line up across columns; 0 uses each row's own height.
    property real fixedRowHeight: 0
    property real rowSpacing: Tokens.spacing.xxs

    // Secondary appears in the second half of the motion and leaves first on collapse.
    readonly property real secondaryRevealProgress: Math.max(0, (root.expansionProgress - 0.4) / 0.6)

    readonly property Item topRow: root.primaryOnTop ? primaryLoader : secondaryLoader
    readonly property real stackTop: (Tokens.bar.expandedHeight - primaryLoader.visualHeight - root.rowSpacing - secondaryLoader.visualHeight) / 2

    // Width of the always-visible row only; the bar sizes from this so hidden rows never resize it.
    readonly property real primaryWidth: primaryLoader.implicitWidth * primaryLoader.itemScale

    implicitWidth: Math.max(primaryLoader.implicitWidth * primaryLoader.itemScale, secondaryLoader.implicitWidth * secondaryLoader.itemScale)

    function xForWidth(w) {
        if (root.alignment === Qt.AlignRight)
            return root.width - w;
        if (root.alignment === Qt.AlignHCenter)
            return (root.width - w) / 2;
        return 0;
    }

    function stackedYFor(row) {
        return row === root.topRow ? root.stackTop : root.stackTop + root.topRow.visualHeight + root.rowSpacing;
    }

    Loader {
        id: primaryLoader

        // Rows may scale their item (around its center); layout uses the visible size.
        readonly property real itemScale: item ? item.scale : 1
        readonly property real visualHeight: height * itemScale
        readonly property real restY: (Tokens.bar.collapsedHeight - visualHeight) / 2

        sourceComponent: root.primaryComponent
        width: Math.min(implicitWidth, root.width / itemScale)
        height: root.fixedRowHeight > 0 ? root.fixedRowHeight : implicitHeight
        x: root.xForWidth(width * itemScale) - width * (1 - itemScale) / 2
        y: restY + root.expansionProgress * (root.stackedYFor(primaryLoader) - restY) - height * (1 - itemScale) / 2
    }

    Loader {
        id: secondaryLoader

        readonly property real itemScale: item ? item.scale : 1
        readonly property real visualHeight: height * itemScale

        sourceComponent: root.secondaryComponent
        width: Math.min(implicitWidth, root.width / itemScale)
        height: root.fixedRowHeight > 0 ? root.fixedRowHeight : implicitHeight
        x: root.xForWidth(width * itemScale) - width * (1 - itemScale) / 2
        // Slides in from the primary row's side.
        y: root.stackedYFor(secondaryLoader) - height * (1 - itemScale) / 2 + (1 - root.secondaryRevealProgress) * (root.primaryOnTop ? -Tokens.spacing.xs : Tokens.spacing.xs)
        opacity: root.secondaryRevealProgress
        visible: opacity > 0
        // Enable as soon as expanding starts so disabled-dimming never shows during the reveal.
        enabled: root.expanded
    }
}
