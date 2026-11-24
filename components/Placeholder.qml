import QtQuick

import qs
import qs.themes

// A faint shape standing in for content that isn't there, so an empty state keeps the layout of a
// full one: a dot where an icon goes, a bar where a line of text goes, a square where art goes.
// Fully round unless `radius` is set.
StyledRectangle {
    id: root

    radius: Tokens.radius.full
    color: Qt.alpha(Theme.color.m3onSurfaceVariant, Tokens.opacity.placeholder)
}
