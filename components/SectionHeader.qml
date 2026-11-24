import QtQuick

import qs
import qs.themes

StyledText {
    id: root

    x: Tokens.spacing.md
    width: (parent?.width ?? 0) - 2 * Tokens.spacing.md
    elideText: true
    animateFontSize: false
    font.pixelSize: Tokens.fontSize.xs
    color: Theme.color.m3onSurfaceVariant
}
