import QtQuick
import qs

Item {
    id: root

    default property alias content: contentHolder.data

    property bool revealed: false
    property real leadingGap: 0
    property real trailingGap: 0
    property real progress: root.revealed ? 1 : 0

    implicitWidth: (root.leadingGap + contentHolder.width + root.trailingGap) * root.progress
    implicitHeight: contentHolder.height
    visible: root.progress > 0

    Item {
        id: contentHolder

        x: root.leadingGap * root.progress + (root.width - (root.leadingGap + root.trailingGap) * root.progress - width) / 2
        width: childrenRect.width
        height: childrenRect.height
        anchors.verticalCenter: parent.verticalCenter
        opacity: root.progress
        scale: 0.6 + 0.4 * root.progress
    }

    Behavior on progress {
        Anim {
            duration: Tokens.animDuration.spatialFast
            easing.type: Easing.OutCubic
        }
    }
}
