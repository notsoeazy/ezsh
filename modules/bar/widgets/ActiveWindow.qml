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
    readonly property string iconPath: IconService.source(root.desktopEntry?.icon ?? "")

    implicitWidth: Tokens.icon.md + Tokens.spacing.xs + nameLabel.implicitWidth
    implicitHeight: Math.max(Tokens.icon.md, nameLabel.implicitHeight)

    Item {
        id: iconBox

        property string iconKey: root.iconPath || `glyph:${HyprlandService.activeWindow ? "web_asset" : "desktop_windows"}`
        readonly property bool isGlyph: iconBox.iconKey.startsWith("glyph:")

        anchors.verticalCenter: parent.verticalCenter
        width: Tokens.icon.md
        height: Tokens.icon.md

        Behavior on iconKey {
            SequentialAnimation {
                Anim {
                    target: iconBox
                    properties: "opacity,scale"
                    to: 0
                    duration: Tokens.animDuration.effectsFast
                    easing.type: Easing.InCubic
                }
                PropertyAction {}
                ParallelAnimation {
                    Anim {
                        target: iconBox
                        property: "opacity"
                        to: 1
                        duration: Tokens.animDuration.effects
                    }
                    Anim {
                        target: iconBox
                        property: "scale"
                        to: 1
                        duration: Tokens.animDuration.spatialFast
                    }
                }
            }
        }

        IconImage {
            id: appIcon

            anchors.fill: parent
            implicitSize: Tokens.icon.md
            source: iconBox.isGlyph ? "" : iconBox.iconKey
            visible: !iconBox.isGlyph && status === Image.Ready
        }

        StyledIcon {
            anchors.centerIn: parent
            iconSize: Tokens.icon.md
            fillAmount: 1
            text: iconBox.isGlyph ? iconBox.iconKey.slice(6) : "web_asset"
            color: Theme.color.m3onSurfaceVariant
            visible: !appIcon.visible
        }
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
