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

    readonly property real iconButtonOverhang: (Tokens.bar.iconButtonSize - Tokens.icon.md) / 2
    readonly property real leftBase: Config.bar.symmetricSides ? Math.max(left.primaryWidth, right.primaryWidth) : left.primaryWidth
    readonly property real rightBase: Config.bar.symmetricSides ? Math.max(left.primaryWidth, right.primaryWidth) : right.primaryWidth
    readonly property real contentWidth: Tokens.bar.horizontalPadding * 2 - root.iconButtonOverhang + root.leftBase + root.rightBase + 2 * Tokens.bar.centerGap + center.width
    readonly property real sidesWidth: root.width - center.width - Tokens.bar.horizontalPadding * 2 + root.iconButtonOverhang - 2 * Tokens.bar.centerGap
    readonly property real leftWidth: Math.max(0, root.leftBase + (root.sidesWidth - root.leftBase - root.rightBase) / 2)
    readonly property real rightWidth: Math.max(0, root.rightBase + (root.sidesWidth - root.leftBase - root.rightBase) / 2)

    // The dashboard row under the expanded bar: always, or ("auto") only while it has something to show.
    readonly property bool dashboardWanted: Config.bar.dashboardMode === "always" || dashboard.hasActivity
    // 0..1; eases the row in and out when activity starts or ends while the bar is open.
    property real dashboardProgress: root.dashboardWanted ? 1 : 0
    // Extra room between the top rows and the dashboard, with the divider centered in it.
    readonly property int dividerGap: Tokens.spacing.xxs
    // Bar sizes the expanded body to these; the row widens it as well as lengthening it.
    readonly property real expandedWidth: Config.bar.expandedWidth
        + Math.max(0, Config.bar.dashboardWidth - Config.bar.expandedWidth) * root.dashboardProgress
    readonly property real expandedHeight: Tokens.bar.expandedHeight
        + (root.dividerGap + dashboard.implicitHeight + Tokens.bar.verticalPadding * 2) * root.dashboardProgress
    readonly property bool popupOpen: dashboard.popupOpen

    signal navigateRequested(string view, string page)

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

        primaryComponent: StatusIcons {
            showNotificationCount: !root.expanded
            onNavigateRequested: (view, page) => root.navigateRequested(view, page)
        }

        secondaryComponent: NotificationSummary {}
    }

    // Separator
    Rectangle {
        x: Tokens.bar.horizontalPadding
        y: Tokens.bar.expandedHeight + root.dividerGap / 2
        width: root.width - Tokens.bar.horizontalPadding * 2
        height: 1
        opacity: dashboard.opacity
        visible: opacity > 0

        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: Qt.alpha(Theme.color.m3outlineVariant, 0)
            }

            GradientStop {
                position: 0.5
                color: Theme.color.m3outlineVariant
            }

            GradientStop {
                position: 1
                color: Qt.alpha(Theme.color.m3outlineVariant, 0)
            }
        }
    }

    Dashboard {
        id: dashboard

        x: Tokens.bar.horizontalPadding
        y: Tokens.bar.expandedHeight + root.dividerGap + Tokens.bar.verticalPadding
        width: root.width - Tokens.bar.horizontalPadding * 2
        height: implicitHeight
        opacity: Math.max(0, (root.progress - Tokens.bar.secondaryRevealStart) / (1 - Tokens.bar.secondaryRevealStart)) * root.dashboardProgress
        visible: opacity > 0
        enabled: root.expanded
    }
}
