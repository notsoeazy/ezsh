import QtQuick

import qs
import qs.themes
import qs.services
import qs.components

Item {
    id: root

    property var apps: []

    property real shownProgress: NotificationService.apps.length > 0 ? 1 : 0
    property real dotsProgress: NotificationService.apps.length > root.pageSize ? 1 : 0

    readonly property int pageSize: 2
    readonly property int rowHeight: 20
    readonly property int rowGap: Tokens.spacing.xxs
    readonly property int appIconSize: Tokens.icon.sm
    readonly property int dotSize: 4

    Behavior on shownProgress {
        Anim {
            duration: Tokens.animDuration.effectsSlow
        }
    }

    Behavior on dotsProgress {
        Anim {
            duration: Tokens.animDuration.effectsSlow
        }
    }

    Binding {
        when: NotificationService.apps.length > 0
        target: root
        property: "apps"
        value: NotificationService.apps
        restoreMode: Binding.RestoreNone
    }

    Column {
        width: parent.width
        spacing: Tokens.spacing.xs

        SectionHeader {
            x: 0
            width: parent.width
            text: "Notifications"
        }

        Item {
            width: parent.width
            height: strip.implicitHeight

            Column {
                width: parent.width
                opacity: 1 - root.shownProgress
                visible: opacity > 0
                spacing: root.rowGap

                Accessible.role: Accessible.StaticText
                Accessible.name: "No notifications"

                Repeater {
                    model: root.pageSize

                    Item {
                        required property int index

                        width: parent.width
                        height: root.rowHeight

                        TextPlaceholder {
                            anchors.verticalCenter: parent.verticalCenter
                            secondary: index > 0
                        }

                        Placeholder {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: root.appIconSize
                            height: root.appIconSize
                        }
                    }
                }
            }

            PagedStrip {
                id: strip

                anchors {
                    left: parent.left
                    right: parent.right
                    rightMargin: (root.dotSize + Tokens.spacing.xs) * root.dotsProgress
                }
                height: parent.height
                opacity: root.shownProgress
                visible: opacity > 0
                vertical: true
                pageSize: root.pageSize
                itemExtent: root.rowHeight
                gap: root.rowGap
                model: root.apps

                delegate: Item {
                    id: appRow

                    required property var modelData

                    width: strip.width
                    height: root.rowHeight

                    TintedIcon {
                        id: appIcon

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        size: root.appIconSize
                        source: IconService.source(appRow.modelData.icon)
                        fallback: "notifications"
                    }

                    StyledText {
                        anchors {
                            left: parent.left
                            right: appIcon.left
                            rightMargin: Tokens.spacing.xs
                            verticalCenter: parent.verticalCenter
                        }

                        elideText: true
                        animateFontSize: false
                        text: appRow.modelData.app
                        font.pixelSize: Tokens.fontSize.sm
                        color: Theme.color.m3onSurface
                    }
                }
            }

            Column {
                id: dots

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                opacity: root.dotsProgress
                visible: opacity > 0
                spacing: Tokens.spacing.xxs

                Repeater {
                    // At least two, so the dots don't drop to one while fading out.
                    model: Math.max(2, strip.pageCount)

                    StyledRectangle {
                        required property int index

                        width: root.dotSize
                        height: root.dotSize
                        radius: Tokens.radius.full
                        color: Qt.alpha(Theme.color.m3onSurfaceVariant, index === strip.shownPage ? 1 : Tokens.opacity.disabledContent)
                    }
                }
            }
        }
    }

    WheelArea {
        anchors.fill: parent
        onStepped: direction => strip.turnPage(-direction)
    }
}
