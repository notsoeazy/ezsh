import QtQuick

import qs
import qs.themes
import qs.services
import qs.components

// The theme selector: a strip of theme cards, each drawn in its own colors. Browsing previews the
// theme across the shell, Tab flips light/dark, Enter applies; closing any other way cancels.
Item {
    id: root

    property int selectedIndex: 0
    property string mode: ThemeService.mode
    // Jump instead of sliding while the strip is first placed.
    property bool placing: true

    readonly property int contentPadding: 12
    readonly property int cardWidth: 168
    readonly property int cardHeight: 92
    readonly property real selectedScale: 1.2
    readonly property int visibleCards: 5
    readonly property int swatchSize: 14
    readonly property real stripHeight: root.cardHeight * root.selectedScale + Tokens.spacing.xs * 2
    readonly property real stripWidth: root.cardWidth * root.visibleCards + Tokens.spacing.xxxl * (root.visibleCards - 1)
    readonly property var selectedTheme: ThemeService.themes[root.selectedIndex] ?? null
    readonly property bool coversOsd: false

    signal closeRequested()

    implicitWidth: Math.min(Screen.width - Tokens.spacing.xxxl * 2, root.stripWidth + root.contentPadding * 2)
    implicitHeight: root.contentPadding * 2 + strip.height + details.height + hints.height + Tokens.spacing.sm * 2

    function select(index) {
        if (ThemeService.themes.length === 0)
            return;
        root.placing = false;
        root.selectedIndex = Math.max(0, Math.min(ThemeService.themes.length - 1, index));
        ThemeService.preview(root.selectedTheme.id, root.mode);
    }

    function toggleMode() {
        root.mode = root.mode === "dark" ? "light" : "dark";
        if (root.selectedTheme)
            ThemeService.preview(root.selectedTheme.id, root.mode);
    }

    function apply() {
        if (root.selectedTheme)
            ThemeService.set(root.selectedTheme.id, root.mode);
        root.closeRequested();
    }

    function placeOnCurrent() {
        root.placing = true;
        root.mode = ThemeService.mode;
        root.selectedIndex = Math.max(0, ThemeService.themes.findIndex(theme => theme.id === ThemeService.current));
    }

    // The card's colors in the chosen mode; a dark-only theme shows its dark colors.
    function previewOf(theme) {
        return theme.preview[root.mode] ?? theme.preview.dark;
    }

    Component.onCompleted: {
        root.placeOnCurrent();
        ThemeService.refresh();
    }

    Connections {
        target: ViewService

        function onViewChanged() {
            if (ViewService.view === "theme")
                root.placeOnCurrent();
            else
                ThemeService.clearPreview();
        }
    }

    Connections {
        target: ThemeService

        function onThemesChanged() {
            if (root.placing)
                root.placeOnCurrent();
        }
    }

    Carousel {
        id: strip

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: root.contentPadding
        }

        height: root.stripHeight
        itemWidth: root.cardWidth
        itemHeight: root.cardHeight
        focus: true
        model: ThemeService.themes
        currentIndex: root.selectedIndex
        instant: root.placing

        delegate: CarouselCard {
            id: card

            required property var modelData
            required property int index

            readonly property var colors: root.previewOf(card.modelData)

            width: root.cardWidth
            height: strip.height
            cardWidth: root.cardWidth
            cardHeight: root.cardHeight
            selectedScale: root.selectedScale
            selected: card.index === root.selectedIndex
            color: card.colors.surface
            accessibleName: card.modelData.name

            onClicked: root.select(card.index)

            Column {
                anchors.centerIn: parent
                spacing: Tokens.spacing.sm

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Tokens.spacing.xs

                    Repeater {
                        model: card.colors.swatches

                        StyledRectangle {
                            id: swatch

                            required property string modelData

                            width: root.swatchSize
                            height: root.swatchSize
                            radius: Tokens.radius.full
                            color: swatch.modelData
                        }
                    }
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    animateFontSize: false
                    text: card.modelData.name
                    font.pixelSize: card.selected ? Tokens.fontSize.md : Tokens.fontSize.sm
                    color: card.colors.onSurface
                }
            }
        }

        Keys.onTabPressed: root.toggleMode()

        onSelectRequested: index => root.select(index)
        onAccepted: root.apply()
        onCancelled: root.closeRequested()
    }

    Item {
        id: details

        anchors {
            top: strip.bottom
            left: parent.left
            right: parent.right
            topMargin: Tokens.spacing.sm
            leftMargin: root.contentPadding + Tokens.spacing.xs
            rightMargin: root.contentPadding + Tokens.spacing.xs
        }

        height: hints.implicitHeight

        StyledText {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            animateFontSize: false
            text: !root.selectedTheme ? "" : root.mode === "light" && !root.selectedTheme.light ? "Dark only" : root.mode === "light" ? "Light" : "Dark"
            font.pixelSize: Tokens.fontSize.xs
            color: Theme.color.m3onSurfaceVariant
        }

        StyledText {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            animateFontSize: false
            text: ThemeService.themes.length > 0 ? `${root.selectedIndex + 1} of ${ThemeService.themes.length}` : ""
            font.pixelSize: Tokens.fontSize.xs
            color: Theme.color.m3onSurfaceVariant
        }
    }

    KeyHints {
        id: hints

        anchors {
            top: details.bottom
            left: parent.left
            right: parent.right
            topMargin: Tokens.spacing.sm
            leftMargin: root.contentPadding + Tokens.spacing.xs
            rightMargin: root.contentPadding + Tokens.spacing.xs
        }

        hints: [
            {
                keys: ["esc"],
                label: "cancel"
            },
            "spacer",
            {
                keys: ["tab"],
                label: root.mode === "dark" ? "light" : "dark"
            },
            {
                keys: ["←→"],
                label: "browse"
            },
            {
                keys: ["↵"],
                label: "apply"
            }
        ]
    }
}
