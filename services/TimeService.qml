
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property date now: systemClock.date

    readonly property string clockText: Qt.formatDateTime(root.now, "h:mm AP")

    readonly property string longDate: Qt.formatDateTime(root.now, "dddd, MMMM d")

    readonly property string shortDate: Qt.formatDateTime(root.now, "ddd, MMM d")

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }
}
