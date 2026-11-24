import QtQuick
import Quickshell

import qs
import qs.themes
import qs.components

Menu {
    id: root

    property var trayItem: null
    property var submenuPath: []
    readonly property var shownOpener: root.submenuPath.length === 0 ? topOpener
        : submenuOpeners.count >= root.submenuPath.length ? submenuOpeners.objectAt(root.submenuPath.length - 1) : null

    // Shows another level: the entries fade in while the popup eases to their size.
    function showPath(path) {
        root.submenuPath = path;
        entriesFade.restart();
    }

    function openFor(item, anchor) {
        if (!item?.hasMenu)
            return;
        root.trayItem = item;
        root.submenuPath = [];
        root.openBelow(anchor);
    }

    leftAligned: true
    // Holds the old level's overflow in while the popup shrinks to a shorter one.
    clip: true

    onClosed: {
        root.trayItem = null;
        root.submenuPath = [];
    }

    // Only while open: the open transition already covers the first size.
    Behavior on implicitHeight {
        enabled: root.opened

        Anim {
            duration: Tokens.animDuration.spatialFast
        }
    }

    Behavior on width {
        enabled: root.opened

        Anim {
            duration: Tokens.animDuration.spatialFast
        }
    }

    Anim {
        id: entriesFade

        target: root.contentItem
        property: "opacity"
        from: 0
        to: 1
        duration: Tokens.animDuration.effects
    }

    QsMenuOpener {
        id: topOpener

        menu: root.trayItem?.menu ?? null
    }

    Instantiator {
        id: submenuOpeners

        // A ScriptModel keeps the openers of the levels above alive while one is pushed or popped.
        model: ScriptModel {
            values: root.submenuPath
        }

        QsMenuOpener {
            required property var modelData

            menu: modelData
        }
    }

    MenuItem {
        visible: root.submenuPath.length > 0
        dense: true
        icon: "arrow_back"
        text: "Back"
        onClicked: root.showPath(root.submenuPath.slice(0, -1))
    }

    Repeater {
        model: root.shownOpener?.children ?? null

        Loader {
            id: entryLoader

            required property var modelData

            width: parent?.width ?? 0
            sourceComponent: entryLoader.modelData.isSeparator ? separatorComponent : entryComponent

            Component {
                id: separatorComponent

                Item {
                    implicitHeight: Tokens.spacing.xs * 2

                    StyledRectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: Tokens.spacing.sm
                        width: parent.width - Tokens.spacing.sm * 2
                        height: 1
                        color: Theme.color.m3outlineVariant
                    }
                }
            }

            Component {
                id: entryComponent

                MenuItem {
                    readonly property var entry: entryLoader.modelData
                    readonly property bool checked: entry.checkState === Qt.Checked

                    dense: true
                    enabled: entry.enabled
                    text: entry.text
                    icon: entry.buttonType === QsMenuButtonType.CheckBox ? (checked ? "check_box" : "check_box_outline_blank")
                        : entry.buttonType === QsMenuButtonType.RadioButton ? (checked ? "radio_button_checked" : "radio_button_unchecked") : ""
                    trailingIcon: entry.hasChildren ? "chevron_right" : ""
                    onClicked: {
                        if (entry.hasChildren) {
                            root.showPath(root.submenuPath.concat([entry]));
                        } else {
                            entry.triggered();
                            root.close();
                        }
                    }
                }
            }
        }
    }
}
