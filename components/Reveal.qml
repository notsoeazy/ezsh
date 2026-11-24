import QtQuick
import qs

Item {
    id: root

    default property alias content: contentHolder.data

    property bool revealed: false
    property real leadingGap: 0
    property real trailingGap: 0
    property bool vertical: false
    property real columnSpacing: 0
    property real progress: root.revealed ? 1 : 0

    implicitWidth: root.vertical ? contentHolder.width
        : (root.leadingGap + contentHolder.width + root.trailingGap) * root.progress
    implicitHeight: root.vertical ? (contentHolder.height + root.columnSpacing) * root.progress - root.columnSpacing
        : contentHolder.height
    visible: root.revealed || root.progress > 0
    clip: root.vertical

    Item {
        id: contentHolder

        x: root.vertical ? 0 : root.leadingGap * root.progress + (root.width - (root.leadingGap + root.trailingGap) * root.progress - width) / 2
        width: root.vertical ? root.width : childrenRect.width
        height: childrenRect.height
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        opacity: root.progress
        scale: root.vertical ? 1 : 0.6 + 0.4 * root.progress
    }

    Behavior on progress {
        Anim {
            duration: Tokens.animDuration.spatialFast
        }
    }
}
