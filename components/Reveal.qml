import QtQuick
import qs

// Shows/hides its content by growing/shrinking its width with a fade and scale,
// so neighbours slide over instead of jumping. Gaps are part of the reveal, so
// put spacing here rather than in the parent Row.
Item {
    id: root

    property bool shown: false
    property real leadingGap: 0
    property real trailingGap: 0
    default property alias content: holder.data

    property real amount: root.shown ? 1 : 0

    Behavior on amount {
        Anim {
            duration: Tokens.animDuration.spatialFast
            easing.type: Easing.OutCubic
        }
    }

    implicitWidth: (root.leadingGap + holder.width + root.trailingGap) * root.amount
    implicitHeight: holder.height
    visible: root.amount > 0

    Item {
        id: holder

        width: childrenRect.width
        height: childrenRect.height
        anchors.verticalCenter: parent.verticalCenter
        x: root.leadingGap * root.amount + (root.width - (root.leadingGap + root.trailingGap) * root.amount - width) / 2
        opacity: root.amount
        scale: 0.6 + 0.4 * root.amount
    }
}
