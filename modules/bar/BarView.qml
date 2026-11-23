import QtQuick

import qs
import qs.config
import qs.themes
import qs.services
import qs.components
import qs.modules.bar.widgets

Item {
    id: root

    required property bool expanded
    required property real progress

    readonly property real iconButtonOverhang: (Tokens.bar.iconButtonSize - Tokens.icon.md) / 2
    readonly property real leftBase: Config.bar.symmetricSides ? Math.max(left.primaryWidth, right.primaryWidth) : left.primaryWidth
    readonly property real rightBase: Config.bar.symmetricSides ? Math.max(left.primaryWidth, right.primaryWidth) : right.primaryWidth
    readonly property real contentWidth: Tokens.bar.horizontalPadding * 2 - root.iconButtonOverhang + root.leftBase + root.rightBase + 2 * Tokens.bar.centerGap + center.width
    readonly property real sidesWidth: root.width - center.width - Tokens.bar.horizontalPadding * 2 + root.iconButtonOverhang - 2 * Tokens.bar.centerGap
    readonly property real leftWidth: Math.max(0, root.leftBase + (root.sidesWidth - root.leftBase - root.rightBase) / 2)
    readonly property real rightWidth: Math.max(0, root.rightBase + (root.sidesWidth - root.leftBase - root.rightBase) / 2)

    signal navigateRequested(string view)

    BarGroup {
        id: left

        x: Tokens.bar.horizontalPadding
        width: root.leftWidth
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

        // Centered, shifted by half the difference when the sides differ (never when symmetric).
        x: (root.width - width + root.leftWidth - root.rightWidth) / 2
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
        width: root.rightWidth
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
