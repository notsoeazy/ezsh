import QtQuick

import qs
import qs.themes
import qs.components

// A small title over a group of controls on a control panel page ("Output", "Power profile").
StyledText {
    x: Tokens.spacing.md
    width: (parent?.width ?? 0) - 2 * Tokens.spacing.md
    elideText: true
    animateFontSize: false
    font.pixelSize: Tokens.fontSize.xs
    color: Theme.color.m3onSurfaceVariant
}
