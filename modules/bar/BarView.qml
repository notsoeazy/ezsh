import QtQuick

import qs
import qs.config
import qs.themes
import qs.services
import qs.components
import qs.modules.bar.widgets
import qs.modules.bar.dashboard

Item {
    id: root

    required property bool expanded
    required property real progress

    property real dashboardProgress: root.dashboardWanted ? 1 : 0
    property bool recordingMenuOpen: false

    readonly property real iconButtonOverhang: (Tokens.bar.iconButtonSize - Tokens.icon.md) / 2
    readonly property real leftBase: Config.bar.symmetricSides ? Math.max(left.primaryWidth, right.primaryWidth) : left.primaryWidth
    readonly property real rightBase: Config.bar.symmetricSides ? Math.max(left.primaryWidth, right.primaryWidth) : right.primaryWidth
    readonly property real contentWidth: Tokens.bar.horizontalPadding * 2 - root.iconButtonOverhang + root.leftBase + root.rightBase + 2 * Tokens.bar.centerGap + center.width
    readonly property real sidesWidth: root.width - center.width - Tokens.bar.horizontalPadding * 2 + root.iconButtonOverhang - 2 * Tokens.bar.centerGap
    readonly property real leftWidth: Math.max(0, root.leftBase + (root.sidesWidth - root.leftBase - root.rightBase) / 2)
    readonly property real rightWidth: Math.max(0, root.rightBase + (root.sidesWidth - root.leftBase - root.rightBase) / 2)
    readonly property bool dashboardWanted: Config.bar.dashboardMode === "always" || dashboard.hasActivity
    readonly property int dividerGap: Tokens.spacing.xxs
    readonly property int dashboardPadding: Tokens.spacing.md
    readonly property real expandedWidth: Config.bar.expandedWidth
        + Math.max(0, Config.bar.dashboardWidth - Config.bar.expandedWidth) * root.dashboardProgress
    readonly property real expandedHeight: Tokens.bar.expandedHeight
        + (root.dividerGap + dashboard.implicitHeight + root.dashboardPadding * 2) * root.dashboardProgress
    readonly property bool popupOpen: dashboard.popupOpen || root.recordingMenuOpen

    signal navigateRequested(string view, string page)

    implicitWidth: root.contentWidth + Math.max(0, root.expandedWidth - root.contentWidth) * root.progress
    implicitHeight: Tokens.bar.collapsedHeight + (root.expandedHeight - Tokens.bar.collapsedHeight) * root.progress

    Behavior on dashboardProgress {
        Anim {}
    }

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
                onClicked: root.navigateRequested("launcher", "")
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter

                Workspaces {
                    anchors.verticalCenter: parent.verticalCenter
                }

                RecordingIndicator {
                    anchors.verticalCenter: parent.verticalCenter
                    onMenuOpenChanged: root.recordingMenuOpen = menuOpen
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
            readonly property real animatedFontSize: Tokens.fontSize.md + (Tokens.fontSize.xl - Tokens.fontSize.md) * root.progress

            text: TimeService.clockText
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

        primaryComponent: StatusIcons {
            showNotificationCount: !root.expanded
            onNavigateRequested: (view, page) => root.navigateRequested(view, page)
        }

        secondaryComponent: NotificationSummary {}
    }

    Divider {
        x: Tokens.bar.horizontalPadding
        y: Tokens.bar.expandedHeight + root.dividerGap / 2
        width: root.width - Tokens.bar.horizontalPadding * 2
        fadeEnds: true
        opacity: dashboard.opacity
        visible: opacity > 0
    }

    Dashboard {
        id: dashboard

        x: Tokens.bar.horizontalPadding
        y: Tokens.bar.expandedHeight + root.dividerGap + root.dashboardPadding
        width: root.width - Tokens.bar.horizontalPadding * 2
        height: implicitHeight
        opacity: left.secondaryRevealProgress * root.dashboardProgress
        visible: opacity > 0
        enabled: root.expanded
    }
}
