
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property date now: clock.date

    readonly property string time: Qt.formatDateTime(root.now, "h:mm AP")

    readonly property string dateText: Qt.formatDateTime(root.now, "dddd, MMMM d")

    readonly property string shortDate: Qt.formatDateTime(root.now, "ddd, MMM d")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
