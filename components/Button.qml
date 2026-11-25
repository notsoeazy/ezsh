import QtQuick

import qs
import qs.themes

Item {
    id: root

    property string icon: ""
    property string text: ""
    property string type: "tonal"
    property bool checked: false
    property bool iconFilled: root.checked
    property real buttonHeight: root.defaultHeight
    property int iconSize: Tokens.icon.md
    property real iconRotation: 0
    // Overrides for the leading / trailing corners, for buttons joined to another (SplitButton); -1 keeps the pill.
    property real startRadius: -1
    property real endRadius: -1
    property color containerColor: root.checked || root.type === "filled" ? Theme.color.m3primary
        : root.type === "standard" ? Qt.alpha(Theme.color.m3onSurface, 0) : Theme.color.m3surfaceContainerHigh
    property color contentColor: root.checked || root.type === "filled" ? Theme.color.m3onPrimary
        : root.type === "standard" ? Theme.color.m3onSurfaceVariant : Theme.color.m3onSurface

    property real pressAmount: mouseArea.pressed ? 1 : 0

    readonly property int defaultHeight: 40
    readonly property real pillRadius: root.height / 2
    readonly property real cornerRadius: root.pillRadius + (Tokens.radius.md - root.pillRadius) * root.pressAmount

    readonly property alias hovered: mouseArea.containsMouse

    signal clicked()
    signal secondaryClicked()

    implicitHeight: root.buttonHeight
    implicitWidth: root.text === "" ? root.buttonHeight : content.implicitWidth + Tokens.spacing.md * 2
    opacity: root.enabled ? 1 : Tokens.opacity.disabledContent
    activeFocusOnTab: true

    Accessible.role: Accessible.Button
    Accessible.name: root.text || root.icon
    Accessible.onPressAction: root.clicked()

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.clicked();
            event.accepted = true;
        }
    }

    Behavior on startRadius {
        Anim {
            duration: Tokens.animDuration.spatial
            easing.type: Easing.OutBack
        }
    }

    Behavior on endRadius {
        Anim {
            duration: Tokens.animDuration.spatial
            easing.type: Easing.OutBack
        }
    }

    Behavior on pressAmount {
        Anim {
            duration: Tokens.animDuration.spatialSlow
            easing.type: Easing.OutBack
        }
    }

    StyledRectangle {
        id: container

        anchors.fill: parent
        color: root.containerColor
        topLeftRadius: root.startRadius >= 0 ? root.startRadius : root.cornerRadius
        bottomLeftRadius: topLeftRadius
        topRightRadius: root.endRadius >= 0 ? root.endRadius : root.cornerRadius
        bottomRightRadius: topRightRadius
        border.width: root.activeFocus ? Tokens.stroke.thick : 0
        border.color: Theme.color.m3secondary

        StateLayer {
            tint: root.contentColor
            hovered: mouseArea.containsMouse
            pressed: mouseArea.pressed
        }
    }

    Row {
        id: content

        anchors.centerIn: parent
        spacing: Tokens.spacing.xs

        StyledIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            text: root.icon
            iconSize: root.iconSize
            fillAmount: root.iconFilled ? 1 : 0
            animateTextChange: true
            color: root.contentColor
            rotation: root.iconRotation

            Behavior on rotation {
                Anim {
                    duration: Tokens.animDuration.spatialFast
                }
            }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.text !== ""
            animateFontSize: false
            text: root.text
            font.pixelSize: Tokens.fontSize.sm
            font.weight: Tokens.font.semibold
            color: root.contentColor
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => event.button === Qt.RightButton ? root.secondaryClicked() : root.clicked()
    }
}
