import QtQuick
import QtQuick.Controls as Controls

import qs
import qs.themes

Controls.Popup {
    id: root

    default property alias items: column.data

    // Follows the intent (open / close requested), not the transitions, so a chevron turns with it.
    property bool shown: false
    // Open from the anchor's left edge instead of its right (for an anchor at the left of the bar).
    property bool leftAligned: false

    readonly property int minWidth: 160
    readonly property int maxWidth: 280
    readonly property real itemsWidth: {
        let width = 0;
        for (const item of column.children)
            width = Math.max(width, item.implicitWidth);
        return width;
    }

    function openBelow(anchor) {
        root.parent = anchor;
        root.x = root.leftAligned ? 0 : anchor.width - root.width;
        root.y = anchor.height + Tokens.spacing.xxs;
        root.open();
    }

    function toggle(anchor) {
        if (root.shown)
            root.close();
        else
            root.openBelow(anchor);
    }

    width: Math.max(root.minWidth, Math.min(root.maxWidth, root.itemsWidth + root.padding * 2))
    padding: Tokens.spacing.xs
    modal: true
    dim: false
    focus: true
    closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside
    transformOrigin: root.leftAligned ? Controls.Popup.TopLeft : Controls.Popup.TopRight

    onAboutToShow: root.shown = true
    onAboutToHide: root.shown = false

    enter: Transition {
        Anim {
            property: "opacity"
            from: 0
            to: 1
            duration: Tokens.animDuration.effects
        }
        Anim {
            property: "scale"
            from: 0.9
            to: 1
            duration: Tokens.animDuration.spatialFast
        }
    }

    exit: Transition {
        Anim {
            property: "opacity"
            to: 0
            duration: Tokens.animDuration.effectsFast
        }
        Anim {
            property: "scale"
            to: 0.95
            duration: Tokens.animDuration.effectsFast
        }
    }

    background: StyledRectangle {
        radius: Tokens.radius.xl
        color: Theme.color.m3surfaceContainerHigh
    }

    contentItem: Column {
        id: column
    }
}
