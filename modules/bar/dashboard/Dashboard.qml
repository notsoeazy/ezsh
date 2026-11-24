import QtQuick

import qs
import qs.services

Item {
    id: root

    readonly property int mediaWidth: 200
    readonly property int columnGap: Tokens.spacing.xxxl
    readonly property real sideWidth: Math.max(0, (root.width - root.mediaWidth - root.columnGap * 2) / 2)
    readonly property bool hasActivity: TrayService.items.length > 0 || MediaService.available || NotificationService.recent.length > 0
    readonly property bool popupOpen: tray.popupOpen

    implicitHeight: media.implicitHeight

    TrayColumn {
        id: tray

        width: root.sideWidth
        height: root.height
        centerY: media.visualCenterY
    }

    MediaColumn {
        id: media

        x: root.sideWidth + root.columnGap
        width: root.mediaWidth
    }

    NotificationColumn {
        x: root.width - width
        width: root.sideWidth
        height: root.height
    }
}
