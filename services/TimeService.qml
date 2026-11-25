
pragma Singleton

import QtQuick
import Quickshell

import qs.config

Singleton {
    id: root

    readonly property date now: systemClock.date

    readonly property string timeFormat: (Config.clock.use24Hour ? "HH:mm" : "h:mm") + (Config.clock.showSeconds ? ":ss" : "") + (Config.clock.use24Hour ? "" : " AP")

    readonly property string clockText: Qt.formatDateTime(root.now, root.timeFormat)

    readonly property string longDate: Qt.formatDateTime(root.now, "dddd, MMMM d")

    readonly property string shortDate: Qt.formatDateTime(root.now, "ddd, MMM d")

    SystemClock {
        id: systemClock

        precision: Config.clock.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }
}
