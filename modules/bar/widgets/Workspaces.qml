import QtQuick
import Quickshell

import qs
import qs.config
import qs.themes
import qs.services
import qs.components

// One pill for the workspaces of the current page and for special workspaces.
// Regular: transparent pill with a dot per workspace; changing page slides the
// dots (next page comes in from the right, previous from the left).
// Special: the pill fills with color and shows the special's icon + name; click hides it.
// Scroll anywhere on it to step through workspaces.
Item {
    id: root

    // This bar's own monitor, so each screen shows its own workspace, page and special.
    readonly property var monitor: HyprlandService.monitorFor(QsWindow.window?.screen)
    readonly property int activeWorkspace: root.monitor?.activeWorkspace?.id ?? 1
    readonly property int pageStart: HyprlandService.pageStart(root.activeWorkspace)
    readonly property string activeSpecial: HyprlandService.specialOn(root.monitor?.name ?? "")

    readonly property bool special: root.activeSpecial !== ""
    // Kept while the special content fades out, so its text doesn't vanish first.
    property string specialName: ""
    // The page being drawn; trails pageStart while the slide plays.
    property int shownPageStart: 0

    readonly property real dotsWidth: HyprlandService.pageSize * Tokens.bar.workspaceDot + (HyprlandService.pageSize - 1) * Tokens.bar.workspaceSpacing + Tokens.bar.workspaceActive - Tokens.bar.workspaceDot
    readonly property real specialWidth: Tokens.spacing.xs + specialContent.implicitWidth + Tokens.spacing.sm

    implicitWidth: root.special ? root.specialWidth : root.dotsWidth
    implicitHeight: Tokens.bar.iconButton

    Behavior on implicitWidth {
        Anim {
            duration: Tokens.animDuration.spatialFast
            easing.type: Easing.OutCubic
        }
    }

    function syncSpecialName() {
        if (root.activeSpecial)
            root.specialName = root.activeSpecial;
    }

    Component.onCompleted: {
        root.shownPageStart = root.pageStart;
        root.syncSpecialName();
    }

    onActiveSpecialChanged: root.syncSpecialName()

    onPageStartChanged: {
        pageSlide.direction = root.pageStart > root.shownPageStart ? 1 : -1;
        pageSlide.restart();
    }

    StyledRectangle {
        id: container

        anchors.fill: parent
        radius: Tokens.radius.full
        // Fade alpha only, so the fill doesn't pass through black.
        color: root.special ? Theme.color.m3primaryContainer : Qt.alpha(Theme.color.m3primaryContainer, 0)
        clip: true

        Row {
            id: dots

            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.bar.workspaceSpacing
            opacity: root.special ? 0 : 1
            scale: root.special ? 0.8 : 1

            Behavior on opacity {
                Anim {
                    duration: Tokens.animDuration.effectsFast
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                Anim {
                    duration: Tokens.animDuration.spatialFast
                    easing.type: Easing.OutCubic
                }
            }

            Repeater {
                id: repeater

                model: HyprlandService.pageSize

                delegate: StyledRectangle {
                    required property int index
                    readonly property int wsId: root.shownPageStart + index + 1
                    readonly property bool active: root.activeWorkspace === wsId
                    readonly property bool occupied: HyprlandService.isOccupied(wsId)

                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: active ? Tokens.bar.workspaceActive : Tokens.bar.workspaceDot
                    implicitHeight: Tokens.bar.workspaceDot
                    radius: Tokens.radius.full

                    color: active ? Theme.color.m3primary
                        : occupied ? Theme.color.m3onSurfaceVariant
                        : Theme.color.m3surfaceVariant

                    Behavior on implicitWidth {
                        Anim {}
                    }
                }
            }
        }

        Row {
            id: specialContent

            anchors.verticalCenter: parent.verticalCenter
            x: Tokens.spacing.xs
            spacing: Tokens.spacing.xxs
            opacity: root.special ? 1 : 0
            scale: root.special ? 1 : 0.8
            visible: opacity > 0

            Behavior on opacity {
                Anim {
                    duration: Tokens.animDuration.effectsFast
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                Anim {
                    duration: Tokens.animDuration.spatialFast
                    easing.type: Easing.OutCubic
                }
            }

            StyledIcon {
                anchors.verticalCenter: parent.verticalCenter
                iconSize: Tokens.icon.sm
                fill: 1
                text: Config.bar.specialIcons[root.specialName] ?? "layers"
                color: Theme.color.m3onPrimaryContainer
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.specialName
                font.pixelSize: Tokens.fontSize.xs
                font.weight: Tokens.font.semibold
                color: Theme.color.m3onPrimaryContainer
            }
        }
    }

    // Out with the old page, swap, in with the new one from the opposite side.
    SequentialAnimation {
        id: pageSlide

        property int direction: 1

        Anim {
            target: dots
            property: "x"
            to: -pageSlide.direction * root.width
            duration: Tokens.animDuration.effectsFast
            easing.type: Easing.InCubic
        }
        ScriptAction {
            script: {
                root.shownPageStart = root.pageStart;
                dots.x = pageSlide.direction * root.width;
            }
        }
        Anim {
            target: dots
            property: "x"
            to: 0
            duration: Tokens.animDuration.spatialFast
            easing.type: Easing.OutCubic
        }
    }

    MouseArea {
        id: mouse

        // Accumulated wheel delta so touchpads step once per notch, not per event.
        property real wheel: 0

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: event => {
            if (root.special) {
                HyprlandService.toggleSpecial(root.specialName);
                return;
            }
            // The dot whose center is closest to the click.
            let best = 0;
            let bestDist = Infinity;
            for (let i = 0; i < repeater.count; i++) {
                const dot = repeater.itemAt(i);
                const dist = Math.abs(event.x - (dots.x + dot.x + dot.width / 2));
                if (dist < bestDist) {
                    best = i;
                    bestDist = dist;
                }
            }
            const id = root.shownPageStart + best + 1;
            if (id !== root.activeWorkspace)
                HyprlandService.switchTo(id);
        }

        onWheel: event => {
            mouse.wheel += event.angleDelta.y;
            if (Math.abs(mouse.wheel) < 120)
                return;
            // Wheel up goes back, like SUPER + mouse_up in the Hyprland binds.
            HyprlandService.switchTo(root.activeWorkspace + (mouse.wheel > 0 ? -1 : 1));
            mouse.wheel = 0;
        }
    }
}
