import QtQuick

import qs.components

Placeholder {
    id: root

    property bool secondary: false

    readonly property int barHeight: 8
    readonly property real primaryWidthFraction: 0.6
    readonly property real secondaryWidthFraction: 0.4

    width: (parent?.width ?? 0) * (root.secondary ? root.secondaryWidthFraction : root.primaryWidthFraction)
    height: root.barHeight
}
