import QtQuick

import qs
import qs.config

// One bar column with two rows. The primary row is always shown: centered in
// the collapsed bar, it slides into the two-row stack when expanded. The
// secondary row only fades/slides in once expanded. Expanded, the stack as a
// whole is vertically centered in the bar.
Item {
    id: root

    property Component primary
    property Component secondary
    // Center column keeps its primary (the clock) on top; sides keep theirs on the bottom.
    property bool primaryOnTop: false
    property int alignment: Qt.AlignLeft // AlignLeft | AlignHCenter | AlignRight
    property real progress: 0 // 0 collapsed .. 1 expanded
    property bool expanded: false // target state; progress is the animated value
    // Fixed row height so rows line up across columns; 0 uses each row's own height.
    property real rowHeight: 0
    property real rowSpacing: Tokens.spacing.xxs

    // Secondary appears in the second half of the motion and leaves first on collapse.
    readonly property real revealProgress: Math.max(0, (root.progress - 0.4) / 0.6)

    readonly property Item topRow: root.primaryOnTop ? primaryRow : secondaryRow
    readonly property real stackTop: (Config.bar.expandedHeight - primaryRow.visualHeight - root.rowSpacing - secondaryRow.visualHeight) / 2

    // Width of the always-visible row only; the bar sizes from this so hidden rows never resize it.
    readonly property real primaryWidth: primaryRow.implicitWidth * primaryRow.itemScale

    implicitWidth: Math.max(primaryRow.implicitWidth * primaryRow.itemScale, secondaryRow.implicitWidth * secondaryRow.itemScale)

    function xFor(w) {
        if (root.alignment === Qt.AlignRight)
            return root.width - w;
        if (root.alignment === Qt.AlignHCenter)
            return (root.width - w) / 2;
        return 0;
    }

    function stackY(row) {
        return row === root.topRow ? root.stackTop : root.stackTop + root.topRow.visualHeight + root.rowSpacing;
    }

    Loader {
        id: primaryRow

        // Rows may scale their item (around its center); layout uses the visible size.
        readonly property real itemScale: item ? item.scale : 1
        readonly property real visualHeight: height * itemScale
        readonly property real restY: (Config.bar.collapsedHeight - visualHeight) / 2

        sourceComponent: root.primary
        width: Math.min(implicitWidth, root.width / itemScale)
        height: root.rowHeight > 0 ? root.rowHeight : implicitHeight
        x: root.xFor(width * itemScale) - width * (1 - itemScale) / 2
        y: restY + root.progress * (root.stackY(primaryRow) - restY) - height * (1 - itemScale) / 2
    }

    Loader {
        id: secondaryRow

        readonly property real itemScale: item ? item.scale : 1
        readonly property real visualHeight: height * itemScale

        sourceComponent: root.secondary
        width: Math.min(implicitWidth, root.width / itemScale)
        height: root.rowHeight > 0 ? root.rowHeight : implicitHeight
        x: root.xFor(width * itemScale) - width * (1 - itemScale) / 2
        // Slides in from the primary row's side.
        y: root.stackY(secondaryRow) - height * (1 - itemScale) / 2 + (1 - root.revealProgress) * (root.primaryOnTop ? -Tokens.spacing.xs : Tokens.spacing.xs)
        opacity: root.revealProgress
        visible: opacity > 0
        // Enable as soon as expanding starts so disabled-dimming never shows during the reveal.
        enabled: root.expanded
    }
}
