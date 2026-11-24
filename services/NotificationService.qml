pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// shortcut: only tracks a count for the bar; popups/history come with the notification view.
Singleton {
    id: root

    // shortcut: only the bar icon and OSD read this; popups must honor it once they exist.
    property bool doNotDisturb: false

    readonly property int count: server.trackedNotifications.values.length
    readonly property string summaryText: root.count === 0 ? "All caught up" : root.count === 1 ? "1 notification" : `${root.count} notifications`
    readonly property string icon: root.count === 0 ? "notifications" : "notifications_unread"

    function toggleDoNotDisturb() {
        root.doNotDisturb = !root.doNotDisturb;
    }

    NotificationServer {
        id: server

        onNotification: notification => notification.tracked = true
    }
}
