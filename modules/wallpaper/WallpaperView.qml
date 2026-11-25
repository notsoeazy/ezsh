import QtQuick

import qs
import qs.config
import qs.themes
import qs.services
import qs.components

Item {
    id: root

    property int selectedIndex: 0
    // Jump instead of sliding while the strip is first placed.
    property bool placing: true

    readonly property int contentPadding: 12
    readonly property int thumbWidth: 192
    readonly property real thumbHeight: root.thumbWidth * 9 / 16
    readonly property real selectedScale: 1.25
    readonly property int visibleThumbs: 5
    readonly property real stripHeight: root.thumbHeight * root.selectedScale + Tokens.spacing.xs * 2
    readonly property real stripWidth: root.thumbWidth * root.visibleThumbs + Tokens.spacing.xxxl * (root.visibleThumbs - 1)
    readonly property string selectedPath: WallpaperService.images[root.selectedIndex] ?? ""
    readonly property bool coversOsd: false

    signal closeRequested()

    implicitWidth: Math.min(Screen.width - Tokens.spacing.xxxl * 2, root.stripWidth + root.contentPadding * 2)
    implicitHeight: root.contentPadding * 2 + strip.height + details.height + hints.height + Tokens.spacing.sm * 2

    function select(index) {
        if (WallpaperService.images.length === 0)
            return;
        root.placing = false;
        root.selectedIndex = Math.max(0, Math.min(WallpaperService.images.length - 1, index));
        WallpaperService.setPreview(root.selectedPath);
    }

    function apply() {
        WallpaperService.set(root.selectedPath);
        root.closeRequested();
    }

    function placeOnShown() {
        root.placing = true;
        root.selectedIndex = Math.max(0, WallpaperService.images.indexOf(WallpaperService.showing));
    }

    Component.onCompleted: {
        root.placeOnShown();
        // Rescan, so images added since the last open show up.
        WallpaperService.refresh();
    }

    Connections {
        target: ViewService

        function onViewChanged() {
            if (ViewService.view === "wallpaper")
                root.placeOnShown();
            else
                WallpaperService.clearPreview();
        }
    }

    Connections {
        target: WallpaperService

        function onImagesChanged() {
            if (!WallpaperService.images.includes(WallpaperService.preview))
                WallpaperService.clearPreview();
            root.placeOnShown();
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
        itemWidth: root.thumbWidth
        itemHeight: root.thumbHeight
        focus: true
        model: WallpaperService.images
        currentIndex: root.selectedIndex
        instant: root.placing

        delegate: CarouselCard {
            id: thumb

            required property string modelData
            required property int index

            width: root.thumbWidth
            height: strip.height
            cardWidth: root.thumbWidth
            cardHeight: root.thumbHeight
            selectedScale: root.selectedScale
            selected: thumb.index === root.selectedIndex
            accessibleName: thumb.modelData.split("/").pop()

            onClicked: root.select(thumb.index)

            Image {
                anchors.fill: parent
                source: WallpaperService.thumbnails[thumb.modelData] ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

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
            anchors {
                left: parent.left
                right: counter.left
                rightMargin: Tokens.spacing.md
                verticalCenter: parent.verticalCenter
            }

            animateFontSize: false
            elideText: true
            text: root.selectedPath.split("/").pop()
            font.pixelSize: Tokens.fontSize.xs
            color: Theme.color.m3onSurfaceVariant
        }

        StyledText {
            id: counter

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            animateFontSize: false
            text: WallpaperService.images.length > 0 ? `${root.selectedIndex + 1} of ${WallpaperService.images.length}` : ""
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
