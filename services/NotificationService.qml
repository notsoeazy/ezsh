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

    // shortcut: always empty until the notification service keeps a history; fill it then from the
    // tracked notifications as [{ app, icon, title }] (appName, appIcon, summary), newest first.
    // To preview the dashboard's list meanwhile, use these sample entries instead:
    //     { app: "Discord", icon: "discord", title: "New message from Alex" },
    //     { app: "Discord", icon: "discord", title: "Mentioned you in #general" },
    //     { app: "Spotify", icon: "spotify", title: "Your Daily Mix is ready" },
    //     { app: "Steam", icon: "steam", title: "A friend is now online" },
    //     { app: "Firefox", icon: "firefox", title: "Download complete" },
    //     { app: "System", icon: "", title: "Updates available" }
    readonly property var recent: []
    // The apps in `recent`, once each, in order of their newest notification: [{ app, icon }].
    readonly property var apps: root.recent.filter((n, i) => root.recent.findIndex(m => m.app === n.app) === i)
        .map(n => ({ app: n.app, icon: n.icon }))

    function toggleDoNotDisturb() {
        root.doNotDisturb = !root.doNotDisturb;
    }

    NotificationServer {
        id: server

        onNotification: notification => notification.tracked = true
    }
}
