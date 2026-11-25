import QtQuick
import Quickshell.Widgets

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
    readonly property int selectedBorder: 2
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

    ListView {
        id: strip

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: root.contentPadding
        }

        height: root.stripHeight
        orientation: ListView.Horizontal
        spacing: Tokens.spacing.xxxl
        clip: true
        interactive: false
        focus: true
        model: WallpaperService.images
        currentIndex: root.selectedIndex
        highlightMoveDuration: root.placing ? 0 : Tokens.animDuration.spatialFast
        highlightMoveVelocity: -1
        preferredHighlightBegin: (width - root.thumbWidth) / 2
        preferredHighlightEnd: (width + root.thumbWidth) / 2
        highlightRangeMode: ListView.StrictlyEnforceRange

        // Let the first and last thumbnails reach the center.
        header: Item {
            width: Math.max(0, (strip.width - root.thumbWidth) / 2)
            height: strip.height
        }
        footer: Item {
            width: Math.max(0, (strip.width - root.thumbWidth) / 2)
            height: strip.height
        }

        delegate: Item {
            id: thumb

            required property string modelData
            required property int index

            property real factor: thumb.selected ? root.selectedScale : 1

            readonly property bool selected: thumb.index === root.selectedIndex

            width: root.thumbWidth
            height: strip.height
            z: thumb.selected ? 1 : 0

            Accessible.role: Accessible.Button
            Accessible.name: thumb.modelData.split("/").pop()
            Accessible.onPressAction: root.select(thumb.index)

            Behavior on factor {
                Anim {
                    duration: Tokens.animDuration.spatialFast
                }
            }

            ClippingRectangle {
                id: frame

                anchors.centerIn: parent
                width: root.thumbWidth * thumb.factor
                height: root.thumbHeight * thumb.factor
                radius: Tokens.radius.lg
                color: Theme.color.m3surfaceContainerHigh

                Image {
                    anchors.fill: parent
                    source: WallpaperService.thumbnails[thumb.modelData] ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.select(thumb.index)
                }
            }

            StyledRectangle {
                anchors.fill: frame
                radius: frame.radius
                color: "transparent"
                border.width: root.selectedBorder
                border.color: Theme.color.m3primary
                opacity: thumb.selected ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    Anim {
                        duration: Tokens.animDuration.effectsFast
                    }
                }
            }
        }

        Keys.onLeftPressed: root.select(root.selectedIndex - 1)
        Keys.onRightPressed: root.select(root.selectedIndex + 1)
        Keys.onReturnPressed: root.apply()
        Keys.onEnterPressed: root.apply()
        Keys.onEscapePressed: root.closeRequested()
    }

    MouseArea {
        id: wheelArea

        property real pendingDelta: 0

        anchors.fill: strip
        acceptedButtons: Qt.NoButton

        onWheel: event => {
            wheelArea.pendingDelta -= event.angleDelta.y + event.angleDelta.x;
            const steps = Math.trunc(wheelArea.pendingDelta / 120);
            if (steps !== 0) {
                wheelArea.pendingDelta -= steps * 120;
                root.select(root.selectedIndex + steps);
            }
        }
    }

    StyledText {
        anchors.fill: strip
        visible: WallpaperService.images.length === 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elideText: true
        text: `No wallpapers in ${WallpaperService.directory}`
        font.pixelSize: Tokens.fontSize.sm
        color: Theme.color.m3onSurfaceVariant
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
            anchors.right: counter.left
            anchors.rightMargin: Tokens.spacing.md
            anchors.verticalCenter: parent.verticalCenter
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
