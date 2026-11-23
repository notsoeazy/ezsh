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
    required property real progress

    readonly property real iconButtonOverhang: (Tokens.bar.iconButtonSize - Tokens.icon.md) / 2
    readonly property real contentWidth: Tokens.bar.horizontalPadding * 2 - root.iconButtonOverhang + 2 * (Math.max(left.primaryWidth, right.primaryWidth) + Tokens.bar.centerGap) + center.width
    readonly property real sideWidth: Math.max(0, (root.width - center.width - Tokens.bar.horizontalPadding * 2 + root.iconButtonOverhang) / 2 - Tokens.bar.centerGap)

    signal navigateRequested(string view)

    BarGroup {
        id: left

        x: Tokens.bar.horizontalPadding
        width: root.sideWidth
        height: root.height
        expansionProgress: root.progress
        expanded: root.expanded
        fixedRowHeight: Tokens.bar.iconButtonSize
        rowSpacing: Tokens.spacing.xs

        primaryComponent: Row {
            spacing: Tokens.spacing.sm

            DistroLogo {
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.navigateRequested("launcher")
            }

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

        secondaryComponent: ActiveWindow {}
    }

    BarGroup {
        id: center

        x: (root.width - width) / 2
        width: implicitWidth
        height: root.height
        expansionProgress: root.progress
        expanded: root.expanded
        alignment: Qt.AlignHCenter
        primaryOnTop: true

        primaryComponent: StyledText {
            text: TimeService.clockText
            readonly property real animatedFontSize: Tokens.fontSize.md + (Tokens.fontSize.xl - Tokens.fontSize.md) * root.progress
            font.pixelSize: root.expanded ? Tokens.fontSize.xl : Tokens.fontSize.md
            animateFontSize: false
            scale: animatedFontSize / font.pixelSize
            font.weight: Tokens.font.semibold
            color: Theme.color.m3onSurface
        }

        secondaryComponent: StyledText {
            text: TimeService.shortDate
            font.pixelSize: Tokens.fontSize.xs
            color: Theme.color.m3onSurfaceVariant
        }
    }

    BarGroup {
        id: right

        x: root.width - Tokens.bar.horizontalPadding + root.iconButtonOverhang - width
        width: root.sideWidth
        height: root.height
        expansionProgress: root.progress
        expanded: root.expanded
        alignment: Qt.AlignRight
        fixedRowHeight: Tokens.bar.iconButtonSize
        rowSpacing: Tokens.spacing.xs

        primaryComponent: StatusIcons { showNotificationCount: !root.expanded }

        secondaryComponent: NotificationSummary {}
    }
}
