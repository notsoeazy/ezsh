import QtQuick

import qs
import qs.themes
import qs.services
import qs.components

Item {
    id: root

    readonly property int pageSize: 2
    readonly property int rowHeight: 20
    readonly property int rowGap: Tokens.spacing.xxs
    readonly property int appIconSize: Tokens.icon.sm
    readonly property int dotSize: 4
    // The apps listed; the last ones are kept while the list fades out after they all leave.
    property var apps: []
    readonly property int pageCount: Math.max(1, Math.ceil(root.apps.length / root.pageSize))
    readonly property int shownPage: Math.min(root.requestedPage, root.pageCount - 1)
    readonly property real pageHeight: root.pageSize * root.rowHeight + (root.pageSize - 1) * root.rowGap
    
    property int requestedPage: 0
    property real shownProgress: NotificationService.apps.length > 0 ? 1 : 0
    property real dotsProgress: NotificationService.apps.length > root.pageSize ? 1 : 0

    Binding {
        when: NotificationService.apps.length > 0
        target: root
        property: "apps"
        value: NotificationService.apps
        restoreMode: Binding.RestoreNone
    }

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
            height: root.pageHeight

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

            Item {
                anchors {
                    left: parent.left
                    right: parent.right
                    rightMargin: (root.dotSize + Tokens.spacing.xs) * root.dotsProgress
                }
                height: parent.height
                clip: true
                opacity: root.shownProgress
                visible: opacity > 0

                Column {
                    width: parent.width
                    y: -root.shownPage * (root.pageHeight + root.rowGap)
                    spacing: root.rowGap

                    Behavior on y {
                        Anim {
                            duration: Tokens.animDuration.spatialFast
                        }
                    }

                    Repeater {
                        model: root.apps

                        Item {
                            id: appRow

                            required property var modelData

                            width: parent.width
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
                    model: Math.max(2, root.pageCount)

                    StyledRectangle {
                        required property int index

                        width: root.dotSize
                        height: root.dotSize
                        radius: Tokens.radius.full
                        color: Qt.alpha(Theme.color.m3onSurfaceVariant, index === root.shownPage ? 1 : Tokens.opacity.disabledContent)
                    }
                }
            }
        }
    }

    WheelArea {
        anchors.fill: parent
        onStepped: direction => root.requestedPage = Math.max(0, Math.min(root.pageCount - 1, root.shownPage - direction))
    }
}
