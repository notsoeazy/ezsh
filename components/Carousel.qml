import QtQuick

import qs

FocusScope {
    id: root

    required property real itemWidth
    required property real itemHeight

    property alias model: list.model
    property alias delegate: list.delegate
    property int currentIndex: 0
    property bool instant: false

    readonly property alias count: list.count

    readonly property int wheelNotch: 120
    readonly property int placeholderCount: {
        const fit = Math.max(1, Math.floor((root.width + list.spacing) / (root.itemWidth + list.spacing)));
        return fit % 2 === 1 ? fit : fit - 1;
    }

    signal selectRequested(int index)
    signal accepted()
    signal cancelled()

    ListView {
        id: list

        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: Tokens.spacing.xxxl
        clip: true
        interactive: false
        focus: true
        currentIndex: root.currentIndex
        highlightMoveDuration: root.instant ? 0 : Tokens.animDuration.spatialFast
        highlightMoveVelocity: -1
        preferredHighlightBegin: (list.width - root.itemWidth) / 2
        preferredHighlightEnd: (list.width + root.itemWidth) / 2
        highlightRangeMode: ListView.StrictlyEnforceRange

        header: Item {
            width: Math.max(0, (list.width - root.itemWidth) / 2)
            height: list.height
        }
        footer: Item {
            width: Math.max(0, (list.width - root.itemWidth) / 2)
            height: list.height
        }

        Keys.onLeftPressed: root.selectRequested(root.currentIndex - 1)
        Keys.onRightPressed: root.selectRequested(root.currentIndex + 1)
        Keys.onReturnPressed: root.accepted()
        Keys.onEnterPressed: root.accepted()
        Keys.onEscapePressed: root.cancelled()
    }

    Row {
        id: placeholders

        anchors.centerIn: parent
        spacing: list.spacing
        opacity: list.count === 0 ? 1 : 0
        visible: placeholders.opacity > 0

        Behavior on opacity {
            Anim {
                duration: Tokens.animDuration.effectsFast
            }
        }

        Repeater {
            model: placeholders.visible ? root.placeholderCount : 0

            Placeholder {
                width: root.itemWidth
                height: root.itemHeight
                radius: Tokens.radius.lg
            }
        }
    }

    MouseArea {
        id: wheelArea

        property real pendingDelta: 0

        anchors.fill: list
        acceptedButtons: Qt.NoButton

        onWheel: event => {
            wheelArea.pendingDelta -= event.angleDelta.y + event.angleDelta.x;
            const steps = Math.trunc(wheelArea.pendingDelta / root.wheelNotch);
            if (steps !== 0) {
                wheelArea.pendingDelta -= steps * root.wheelNotch;
                root.selectRequested(root.currentIndex + steps);
            }
        }
    }
}
