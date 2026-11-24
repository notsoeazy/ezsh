import QtQuick

import qs

Item {
    id: root

    required property int pageSize
    required property real itemExtent
    
    property alias model: repeater.model
    property alias delegate: repeater.delegate
    property real gap: 0
    property bool vertical: false

    readonly property int pageCount: Math.max(1, Math.ceil(repeater.count / root.pageSize))
    readonly property int shownPage: Math.min(root.requestedPage, root.pageCount - 1)
    readonly property real pageExtent: root.pageSize * root.itemExtent + (root.pageSize - 1) * root.gap
    readonly property real offset: -root.shownPage * (root.pageExtent + root.gap)

    property int requestedPage: 0

    implicitWidth: root.vertical ? 0 : root.pageExtent
    implicitHeight: root.vertical ? root.pageExtent : 0
    clip: true

    function turnPage(direction) {
        root.requestedPage = Math.max(0, Math.min(root.pageCount - 1, root.shownPage + direction));
    }

    Grid {
        x: root.vertical ? 0 : root.offset
        y: root.vertical ? root.offset : 0
        columns: root.vertical ? 1 : Math.max(1, repeater.count)
        rowSpacing: root.gap
        columnSpacing: root.gap

        Behavior on x {
            Anim {
                duration: Tokens.animDuration.spatialFast
            }
        }

        Behavior on y {
            Anim {
                duration: Tokens.animDuration.spatialFast
            }
        }

        Repeater {
            id: repeater
        }
    }
}
