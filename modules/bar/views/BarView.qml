import QtQuick

import qs
import qs.config
import qs.themes
import qs.services
import qs.components
import qs.modules.bar.widgets

// Three columns (left, center, right), each a BarGroup with a hidden second row.
// Sides always get equal width so the clock stays horizontally centered.
Item {
    id: root

    required property bool expanded

    signal navigateRequested(string view)

    // Expansion progress (0..1), owned by Bar.qml so the shape and this content share one clock.
    required property real progress

    // Icon buttons carry their own padding; pull the right column out so glyphs align with the left padding.
    readonly property real rightInset: (Tokens.bar.iconButton - Tokens.icon.md) / 2
    // Width the bar needs to fit the always-visible rows: both sides as wide as the
    // wider one so the clock stays centered. Hidden rows elide within this.
    readonly property real contentWidth: Config.bar.padding * 2 - root.rightInset
        + 2 * (Math.max(left.primaryWidth, right.primaryWidth) + Config.bar.centerGap)
        + center.width
    readonly property real sideWidth: Math.max(0, (root.width - center.width - Config.bar.padding * 2 + root.rightInset) / 2 - Config.bar.centerGap)

    BarGroup {
        id: left

        x: Config.bar.padding
        width: root.sideWidth
        height: root.height
        progress: root.progress
        expanded: root.expanded
        rowHeight: Tokens.bar.iconButton
        rowSpacing: Tokens.spacing.xs

        primary: Row {
            spacing: Tokens.spacing.sm

            DistroLogo {
                anchors.verticalCenter: parent.verticalCenter
                onActivated: root.navigateRequested("launcher")
            }

            // Spacing for the dot lives in its Reveal, so it slides in instead of popping.
            Row {
                anchors.verticalCenter: parent.verticalCenter

                Workspaces {
                    anchors.verticalCenter: parent.verticalCenter
                }

                RecordingIndicator {
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        secondary: ActiveWindow {}
    }

    BarGroup {
        id: center

        x: (root.width - width) / 2
        width: implicitWidth
        height: root.height
        progress: root.progress
        expanded: root.expanded
        alignment: Qt.AlignHCenter
        primaryOnTop: true

        primary: StyledText {
            text: TimeService.time
            // Font jumps to the target size (crisp at rest); scale animates the visible size
            // smoothly from where it was, since pixel sizes can only step in whole pixels.
            readonly property real visualSize: Tokens.fontSize.md + (Tokens.fontSize.xl - Tokens.fontSize.md) * root.progress
            font.pixelSize: root.expanded ? Tokens.fontSize.xl : Tokens.fontSize.md
            animateSize: false
            scale: visualSize / font.pixelSize
            font.weight: Tokens.font.semibold
            color: Theme.color.m3onSurface
        }

        secondary: StyledText {
            text: TimeService.shortDate
            font.pixelSize: Tokens.fontSize.xs
            color: Theme.color.m3onSurfaceVariant
        }
    }

    BarGroup {
        id: right

        x: root.width - Config.bar.padding + root.rightInset - width
        width: root.sideWidth
        height: root.height
        progress: root.progress
        expanded: root.expanded
        alignment: Qt.AlignRight
        rowHeight: Tokens.bar.iconButton
        rowSpacing: Tokens.spacing.xs

        primary: StatusIcons {
            showNotificationCount: !root.expanded
        }
        secondary: NotificationSummary {}
    }
}
