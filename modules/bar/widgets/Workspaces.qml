import QtQuick
import Quickshell

import qs
import qs.config
import qs.themes
import qs.services
import qs.components

Item {
    id: root

    readonly property var monitor: HyprlandService.monitorFor(QsWindow.window?.screen)
    readonly property int activeWorkspaceId: root.monitor?.activeWorkspace?.id ?? 1
    readonly property int pageOffset: HyprlandService.pageOffsetOf(root.activeWorkspaceId)
    readonly property string activeSpecialName: HyprlandService.specialNameOn(root.monitor?.name ?? "")

    readonly property bool showingSpecial: root.activeSpecialName !== ""
    property string lastSpecialName: ""
    property int displayedPageOffset: 0

    readonly property int activeWidth: 22

    readonly property real regularWidth: HyprlandService.workspacesPerPage * Tokens.bar.workspaceDotSize + (HyprlandService.workspacesPerPage - 1) * Tokens.bar.workspaceSpacing + root.activeWidth - Tokens.bar.workspaceDotSize
    readonly property real specialWidth: Tokens.spacing.xs + specialContent.implicitWidth + Tokens.spacing.sm

    implicitWidth: root.showingSpecial ? root.specialWidth : root.regularWidth
    implicitHeight: Tokens.bar.iconButtonSize

    Behavior on implicitWidth {
        Anim {
            duration: Tokens.animDuration.spatialFast
        }
    }

    function rememberSpecialName() {
        if (root.activeSpecialName)
            root.lastSpecialName = root.activeSpecialName;
    }

    Component.onCompleted: {
        root.displayedPageOffset = root.pageOffset;
        root.rememberSpecialName();
    }

    onActiveSpecialNameChanged: root.rememberSpecialName()

    onPageOffsetChanged: {
        pageSlide.direction = root.pageOffset > root.displayedPageOffset ? 1 : -1;
        pageSlide.restart();
    }

    StyledRectangle {
        id: pill

        anchors.fill: parent
        radius: Tokens.radius.full
        // Fade alpha only, so the fill doesn't pass through black.
        color: root.showingSpecial ? Theme.color.m3primaryContainer : Qt.alpha(Theme.color.m3primaryContainer, 0)
        clip: true

        Row {
            id: dotRow

            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.bar.workspaceSpacing
            opacity: root.showingSpecial ? 0 : 1
            scale: root.showingSpecial ? 0.8 : 1

            Behavior on opacity {
                Anim {
                    duration: Tokens.animDuration.effectsFast
                }
            }

            Behavior on scale {
                Anim {
                    duration: Tokens.animDuration.spatialFast
                }
            }

            Repeater {
                id: dotRepeater

                model: HyprlandService.workspacesPerPage

                delegate: StyledRectangle {
                    required property int index
                    readonly property int workspaceId: root.displayedPageOffset + index + 1
                    readonly property bool isActive: root.activeWorkspaceId === workspaceId
                    readonly property bool isOccupied: HyprlandService.isWorkspaceOccupied(workspaceId)

                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: isActive ? root.activeWidth : Tokens.bar.workspaceDotSize
                    implicitHeight: Tokens.bar.workspaceDotSize
                    radius: Tokens.radius.full

                    color: isActive ? Theme.color.m3primary
                        : isOccupied ? Theme.color.m3onSurfaceVariant
                        : Theme.color.m3surfaceVariant

                    Behavior on implicitWidth {
                        Anim {
                            duration: Tokens.animDuration.spatialFast
                        }
                    }
                }
            }
        }

        Row {
            id: specialContent

            anchors.verticalCenter: parent.verticalCenter
            x: Tokens.spacing.xs
            spacing: Tokens.spacing.xxs
            opacity: root.showingSpecial ? 1 : 0
            scale: root.showingSpecial ? 1 : 0.8
            visible: opacity > 0

            Behavior on opacity {
                Anim {
                    duration: Tokens.animDuration.effectsFast
                }
            }

            Behavior on scale {
                Anim {
                    duration: Tokens.animDuration.spatialFast
                }
            }

            StyledIcon {
                anchors.verticalCenter: parent.verticalCenter
                iconSize: Tokens.icon.sm
                fillAmount: 1
                text: Config.bar.specialIcons[root.lastSpecialName] ?? "layers"
                color: Theme.color.m3onPrimaryContainer
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.lastSpecialName
                font.pixelSize: Tokens.fontSize.xs
                font.weight: Tokens.font.semibold
                color: Theme.color.m3onPrimaryContainer
            }
        }
    }

    SequentialAnimation {
        id: pageSlide

        property int direction: 1

        Anim {
            target: dotRow
            property: "x"
            to: -pageSlide.direction * root.width
            duration: Tokens.animDuration.effectsFast
            easing.type: Easing.InCubic
        }
        ScriptAction {
            script: {
                root.displayedPageOffset = root.pageOffset;
                dotRow.x = pageSlide.direction * root.width;
            }
        }
        Anim {
            target: dotRow
            property: "x"
            to: 0
            duration: Tokens.animDuration.spatialFast
        }
    }

    WheelArea {
        id: mouseArea

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor

        onClicked: event => {
            if (root.showingSpecial) {
                HyprlandService.toggleSpecialWorkspace(root.lastSpecialName);
                return;
            }
            let closestDotIndex = 0;
            let closestDistance = Infinity;
            for (let i = 0; i < dotRepeater.count; i++) {
                const dot = dotRepeater.itemAt(i);
                const dist = Math.abs(event.x - (dotRow.x + dot.x + dot.width / 2));
                if (dist < closestDistance) {
                    closestDotIndex = i;
                    closestDistance = dist;
                }
            }
            const id = root.displayedPageOffset + closestDotIndex + 1;
            if (id !== root.activeWorkspaceId)
                HyprlandService.switchToWorkspace(id);
        }

        onStepped: direction => HyprlandService.switchToWorkspace(root.activeWorkspaceId - direction)
    }
}
