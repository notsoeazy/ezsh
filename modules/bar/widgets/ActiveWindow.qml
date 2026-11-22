import QtQuick
import Quickshell
import Quickshell.Widgets

import qs
import qs.themes
import qs.services
import qs.components

// Focused app icon + name.
Item {
    id: root

    readonly property var entry: HyprlandService.appId ? DesktopEntries.heuristicLookup(HyprlandService.appId) : null
    readonly property string iconPath: root.entry?.icon ? Quickshell.iconPath(root.entry.icon, true) : ""

    implicitWidth: Tokens.icon.md + Tokens.spacing.xs + label.implicitWidth
    implicitHeight: Math.max(Tokens.icon.md, label.implicitHeight)

    IconImage {
        id: appIcon

        anchors.verticalCenter: parent.verticalCenter
        implicitSize: Tokens.icon.md
        source: root.iconPath
        visible: root.iconPath !== "" && status === Image.Ready
    }

    StyledIcon {
        anchors.centerIn: appIcon
        iconSize: Tokens.icon.md
        fill: 1
        text: HyprlandService.activeWindow ? "web_asset" : "desktop_windows"
        color: Theme.color.m3onSurfaceVariant
        visible: !appIcon.visible
    }

    StyledText {
        id: label

        anchors {
            left: parent.left
            right: parent.right
            leftMargin: Tokens.icon.md + Tokens.spacing.xs
            verticalCenter: parent.verticalCenter
        }

        elideText: true
        animateText: true
        text: HyprlandService.activeWindow ? (root.entry?.name || HyprlandService.appId || "Desktop") : "Desktop"
        font.pixelSize: Tokens.fontSize.sm
        color: Theme.color.m3onSurface
    }
}
