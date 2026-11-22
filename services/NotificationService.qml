pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// shortcut: only tracks a count for the bar; popups/history come with the notification view.
Singleton {
    id: root

    // shortcut: nothing sets this yet; wire it to a toggle once notification popups exist.
    property bool doNotDisturb: false

    readonly property int count: server.trackedNotifications.values.length
    readonly property string summary: root.count === 0 ? "All caught up" : root.count === 1 ? "1 notification" : `${root.count} notifications`
    readonly property string icon: root.count === 0 ? "notifications" : "notifications_unread"

    NotificationServer {
        id: server

        onNotification: n => n.tracked = true
    }
}
