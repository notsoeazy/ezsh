import QtQuick

import qs
import qs.themes
import qs.services
import qs.components

Item {
    id: root

    required property var modelData

    property string title: ""
    property string subtitle: ""
    property string iconName: ""
    property string symbol: "apps"
    property string glyph: ""
    property bool nerdGlyph: false

    readonly property int tileSize: 32
    readonly property int glyphSize: 22
    // Widest a glyph tile grows for a long glyph ("¯\_(ツ)_/¯"); the glyph shrinks to fit.
    readonly property int glyphMaxWidth: 96

    width: ListView.view?.width ?? 0
    height: Tokens.launcher.rowHeight

    Accessible.role: Accessible.ListItem
    Accessible.name: root.title

    StyledRectangle {
        id: tile

        x: Tokens.spacing.sm
        anchors.verticalCenter: parent.verticalCenter
        width: root.glyph ? Math.max(root.tileSize, glyphText.width + Tokens.spacing.xs) : root.tileSize
        height: root.tileSize
        radius: Tokens.radius.md
        color: Theme.color.m3surfaceContainerHigh

        // A plain Image with an explicit sourceSize, not IconImage: a delegate creates its
        // image before layout gives it a size, and an image loaded at size 0 makes Qt render
        // some SVGs (Inkscape, wine) at their natural size and warn "requested buffer size
        // is too big".
        Image {
            id: appIcon

            readonly property real iconSize: root.tileSize - Tokens.spacing.xxs * 2

            anchors.fill: parent
            anchors.margins: Tokens.spacing.xxs
            fillMode: Image.PreserveAspectFit
            sourceSize: Qt.size(appIcon.iconSize * Screen.devicePixelRatio, appIcon.iconSize * Screen.devicePixelRatio)
            source: IconService.source(root.iconName)
            visible: status === Image.Ready
        }

        StyledText {
            id: glyphText

            anchors.centerIn: parent
            visible: root.glyph !== ""
            animateFontSize: false
            text: root.glyph
            font.family: root.nerdGlyph ? Tokens.font.nerd : Tokens.font.family
            font.pixelSize: root.glyphSize
            width: Math.min(implicitWidth, root.glyphMaxWidth - Tokens.spacing.xs)
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: Tokens.fontSize.xs
            color: Theme.color.m3onSurface
        }

        StyledIcon {
            anchors.centerIn: parent
            iconSize: Tokens.icon.md
            fillAmount: 1
            text: root.symbol
            color: Theme.color.m3onSurfaceVariant
            visible: !appIcon.visible && !glyphText.visible
        }
    }

    Column {
        anchors {
            left: tile.right
            right: parent.right
            leftMargin: Tokens.spacing.sm
            rightMargin: Tokens.spacing.xxxl * 2
            verticalCenter: parent.verticalCenter
        }

        StyledText {
            width: parent.width
            elideText: true
            animateFontSize: false
            text: root.title
            font.pixelSize: Tokens.fontSize.sm
            color: Theme.color.m3onSurface
        }

        StyledText {
            width: parent.width
            visible: text !== ""
            elideText: true
            animateFontSize: false
            text: root.subtitle
            font.pixelSize: Tokens.fontSize.xs
            color: Theme.color.m3onSurfaceVariant
        }
    }
}
