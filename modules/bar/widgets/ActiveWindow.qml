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

    readonly property var desktopEntry: HyprlandService.activeAppId ? DesktopEntries.heuristicLookup(HyprlandService.activeAppId) : null
    readonly property string iconPath: root.desktopEntry?.icon ? Quickshell.iconPath(root.desktopEntry.icon, true) : ""

    implicitWidth: Tokens.icon.md + Tokens.spacing.xs + nameLabel.implicitWidth
    implicitHeight: Math.max(Tokens.icon.md, nameLabel.implicitHeight)

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
        fillAmount: 1
        text: HyprlandService.activeWindow ? "web_asset" : "desktop_windows"
        color: Theme.color.m3onSurfaceVariant
        visible: !appIcon.visible
    }

    StyledText {
        id: nameLabel

        anchors {
            left: parent.left
            right: parent.right
            leftMargin: Tokens.icon.md + Tokens.spacing.xs
            verticalCenter: parent.verticalCenter
        }

        elideText: true
        animateTextChange: true
        text: HyprlandService.activeWindow ? (root.desktopEntry?.name || HyprlandService.activeAppId || "Desktop") : "Desktop"
        font.pixelSize: Tokens.fontSize.sm
        color: Theme.color.m3onSurface
    }
}
