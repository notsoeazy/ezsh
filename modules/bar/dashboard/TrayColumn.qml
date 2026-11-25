import QtQuick
import Quickshell

import qs
import qs.themes
import qs.services
import qs.components

Item {
    id: root

    property real centerY: root.height / 2
    property real shownProgress: root.items.length > 0 ? 1 : 0

    readonly property int pageSize: 3
    readonly property int buttonSize: 36
    readonly property int buttonGap: Tokens.spacing.sm
    readonly property int chevronWidth: 16
    readonly property real chevronRestOpacity: 0.5
    readonly property var items: TrayService.items
    readonly property bool popupOpen: menu.shown

    onEnabledChanged: {
        if (!root.enabled)
            menu.close();
    }

    Behavior on shownProgress {
        Anim {
            duration: Tokens.animDuration.effectsSlow
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.centerY - root.buttonSize / 2
        opacity: 1 - root.shownProgress
        visible: opacity > 0
        spacing: root.buttonGap

        Accessible.role: Accessible.StaticText
        Accessible.name: "No tray apps"

        Repeater {
            model: root.pageSize

            Item {
                width: root.buttonSize
                height: root.buttonSize

                Placeholder {
                    anchors.centerIn: parent
                    width: Tokens.icon.lg
                    height: Tokens.icon.lg
                }
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.centerY - root.buttonSize / 2
        opacity: root.shownProgress
        visible: opacity > 0
        spacing: Tokens.spacing.xxs

        Chevron {
            icon: "chevron_left"
            shown: strip.shownPage > 0
            Accessible.name: "Previous tray apps"
            onClicked: strip.turnPage(-1)
        }

        PagedStrip {
            id: strip

            height: root.buttonSize
            pageSize: root.pageSize
            itemExtent: root.buttonSize
            gap: root.buttonGap
            model: ScriptModel {
                values: root.items
            }

            delegate: Item {
                id: trayButton

                required property var modelData

                width: root.buttonSize
                height: root.buttonSize

                Accessible.role: Accessible.Button
                Accessible.name: trayButton.modelData.tooltipTitle || trayButton.modelData.title || trayButton.modelData.id

                StateLayer {
                    topLeftRadius: root.buttonSize / 2
                    topRightRadius: root.buttonSize / 2
                    bottomLeftRadius: root.buttonSize / 2
                    bottomRightRadius: root.buttonSize / 2
                    hovered: mouseArea.containsMouse
                    pressed: mouseArea.pressed
                }

                TintedIcon {
                    anchors.centerIn: parent
                    size: Tokens.icon.lg
                    source: TrayService.iconSource(trayButton.modelData)
                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: event => {
                        const item = trayButton.modelData;
                        if (event.button === Qt.MiddleButton)
                            TrayService.secondaryActivate(item);
                        else if (event.button === Qt.RightButton || item.onlyMenu)
                            menu.openFor(item, trayButton);
                        else
                            TrayService.activate(item);
                    }
                }
            }
        }

        Chevron {
            icon: "chevron_right"
            shown: strip.shownPage < strip.pageCount - 1
            Accessible.name: "Next tray apps"
            onClicked: strip.turnPage(1)
        }
    }

    WheelArea {
        anchors.fill: parent
        onStepped: direction => strip.turnPage(-direction)
    }

    TrayMenu {
        id: menu
    }

    component Chevron: Item {
        id: chevron

        property string icon
        property bool shown: false

        signal clicked()

        width: root.chevronWidth
        height: root.buttonSize

        Accessible.role: Accessible.Button

        StyledIcon {
            anchors.centerIn: parent
            text: chevron.icon
            iconSize: Tokens.icon.sm
            color: Theme.color.m3onSurfaceVariant
            opacity: !chevron.shown ? 0 : chevronArea.containsMouse ? 1 : root.chevronRestOpacity

            Behavior on opacity {
                Anim {
                    duration: Tokens.animDuration.effectsFast
                }
            }
        }

        MouseArea {
            id: chevronArea

            anchors.fill: parent
            enabled: chevron.shown
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chevron.clicked()
        }
    }
}
