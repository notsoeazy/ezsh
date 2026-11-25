import QtQuick

import qs
import qs.themes
import qs.components

// The rounded container both capture toolbars are drawn in.
StyledRectangle {
    id: root

    default property alias content: row.data

    readonly property int buttonHeight: 36
    readonly property int padding: Tokens.spacing.xxs

    implicitWidth: row.implicitWidth + root.padding * 2
    implicitHeight: row.implicitHeight + root.padding * 2
    radius: Tokens.radius.full
    color: Theme.color.m3surfaceContainer

    // Keeps clicks between buttons from reaching the selection or the drawing underneath.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }

    Row {
        id: row

        x: root.padding
        y: root.padding
        spacing: Tokens.spacing.xxs
    }

    component Separator: Divider {
        anchors.verticalCenter: parent?.verticalCenter
        vertical: true
        height: (parent?.height ?? 0) / 2
    }
}
