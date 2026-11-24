import QtQuick

MouseArea {
    id: root

    property real pendingDelta: 0

    signal stepped(int direction)

    acceptedButtons: Qt.NoButton

    onWheel: event => {
        root.pendingDelta += event.angleDelta.y;
        if (Math.abs(root.pendingDelta) < 120)
            return;
        root.stepped(root.pendingDelta > 0 ? 1 : -1);
        root.pendingDelta = 0;
    }
}
