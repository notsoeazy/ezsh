import QtQuick

import qs
import qs.themes
import qs.services
import qs.components

// The session menu: lock, log out, restart, shut down
Item {
    id: root

    readonly property int contentPadding: Tokens.spacing.md
    readonly property int buttonWidth: 72
    readonly property int buttonHeight: 56
    readonly property var actions: [
        {
            icon: "lock",
            label: "Lock",
            run: () => SessionService.lock()
        },
        {
            icon: "logout",
            label: "Log Out",
            run: () => SessionService.logout()
        },
        {
            icon: "restart_alt",
            label: "Restart",
            run: () => SessionService.reboot()
        },
        {
            icon: "power_settings_new",
            label: "Shut Down",
            run: () => SessionService.poweroff()
        }
    ]
    readonly property bool coversOsd: false

    property int selectedIndex: 0

    signal closeRequested()

    implicitWidth: row.implicitWidth + root.contentPadding * 2
    implicitHeight: row.implicitHeight + root.contentPadding * 2
    focus: true

    function move(direction) {
        root.selectedIndex = (root.selectedIndex + direction + root.actions.length) % root.actions.length;
    }

    function activate(index) {
        const action = root.actions[index];
        root.closeRequested();
        action.run();
    }

    Keys.onLeftPressed: root.move(-1)
    Keys.onRightPressed: root.move(1)
    Keys.onTabPressed: root.move(1)
    Keys.onBacktabPressed: root.move(-1)
    Keys.onReturnPressed: root.activate(root.selectedIndex)
    Keys.onEnterPressed: root.activate(root.selectedIndex)
    Keys.onEscapePressed: root.closeRequested()

    Connections {
        target: ViewService

        function onViewChanged() {
            if (ViewService.view === "session")
                root.selectedIndex = 0;
        }
    }

    Row {
        id: row

        x: root.contentPadding
        y: root.contentPadding
        spacing: Tokens.spacing.sm

        Repeater {
            model: root.actions

            Item {
                id: tile

                required property var modelData
                required property int index

                readonly property bool selected: tile.index === root.selectedIndex

                width: root.buttonWidth
                height: tileColumn.implicitHeight

                Accessible.role: Accessible.Button
                Accessible.name: tile.modelData.label
                Accessible.onPressAction: root.activate(tile.index)

                Column {
                    id: tileColumn

                    spacing: Tokens.spacing.xs

                    StyledRectangle {
                        width: root.buttonWidth
                        height: root.buttonHeight
                        radius: tile.selected ? Tokens.radius.xl : height / 2
                        color: tile.selected ? Theme.color.m3primary : Theme.color.m3surfaceContainerHigh

                        Behavior on radius {
                            Anim {
                                duration: Tokens.animDuration.spatialFast
                                easing.type: Easing.OutBack
                            }
                        }

                        StateLayer {
                            tint: tile.selected ? Theme.color.m3onPrimary : Theme.color.m3onSurface
                            pressed: mouseArea.pressed
                        }

                        StyledIcon {
                            anchors.centerIn: parent
                            text: tile.modelData.icon
                            iconSize: Tokens.icon.lg
                            color: tile.selected ? Theme.color.m3onPrimary : Theme.color.m3onSurface
                        }
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        animateFontSize: false
                        text: tile.modelData.label
                        font.pixelSize: Tokens.fontSize.xs
                        color: tile.selected ? Theme.color.m3onSurface : Theme.color.m3onSurfaceVariant
                    }
                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selectedIndex = tile.index
                    onClicked: root.activate(tile.index)
                }
            }
        }
    }
}
