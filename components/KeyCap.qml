import QtQuick

import qs
import qs.themes

// One keyboard key as a small rounded chip, tinted from its text color.
Rectangle {
    id: root

    required property string text
    property color tint: Theme.color.m3onSurface

    implicitWidth: Math.max(root.implicitHeight, keyText.implicitWidth + Tokens.spacing.xs)
    implicitHeight: keyText.implicitHeight + Tokens.spacing.xxs
    radius: Tokens.radius.sm
    color: Qt.alpha(root.tint, Tokens.opacity.hover)

    StyledText {
        id: keyText

        anchors.centerIn: parent
        animateFontSize: false
        text: root.text
        font.pixelSize: Tokens.fontSize.xs
        font.weight: Tokens.font.semibold
        color: root.tint
    }
}
