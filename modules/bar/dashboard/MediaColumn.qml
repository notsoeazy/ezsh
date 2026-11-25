import QtQuick
import Quickshell.Widgets

import qs
import qs.themes
import qs.services
import qs.components

Column {
    id: root

    property real shownProgress: MediaService.available ? 1 : 0
    property string shownTitle: ""
    property string shownArtist: ""
    property string shownArtUrl: ""

    readonly property int artSize: 40
    readonly property int glyphSpaceBelow: Tokens.spacing.xxs
    readonly property real visualCenterY: (root.implicitHeight - root.glyphSpaceBelow) / 2
    readonly property int positionPollInterval: 1000
    readonly property int seekStep: 5

    spacing: Tokens.spacing.xxs

    Behavior on shownProgress {
        Anim {
            duration: Tokens.animDuration.effectsSlow
        }
    }

    Binding {
        when: MediaService.available
        target: root
        property: "shownTitle"
        value: MediaService.title || MediaService.playerName
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: MediaService.available
        target: root
        property: "shownArtist"
        value: MediaService.artist || MediaService.playerName
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: MediaService.available
        target: root
        property: "shownArtUrl"
        value: MediaService.artUrl
        restoreMode: Binding.RestoreNone
    }

    Timer {
        running: root.visible && MediaService.playing
        triggeredOnStart: true
        repeat: true
        interval: root.positionPollInterval
        onTriggered: MediaService.refreshPosition()
    }

    Row {
        width: parent.width
        spacing: Tokens.spacing.sm

        ClippingRectangle {
            width: root.artSize
            height: root.artSize
            radius: Tokens.radius.md
            color: Qt.alpha(Theme.color.m3surfaceContainerHighest, root.shownProgress)

            Placeholder {
                anchors.fill: parent
                radius: 0
                opacity: 1 - root.shownProgress
                visible: opacity > 0
            }

            StyledIcon {
                anchors.centerIn: parent
                opacity: root.shownProgress
                visible: opacity > 0 && art.loadedProgress < 1
                text: "music_note"
                iconSize: Tokens.icon.md
                color: Theme.color.m3onSurfaceVariant
            }

            Image {
                id: art

                // 0..1, fades a newly loaded cover in instead of popping it.
                property real loadedProgress: art.status === Image.Ready ? 1 : 0

                anchors.fill: parent
                source: root.shownArtUrl
                sourceSize.width: root.artSize * Screen.devicePixelRatio
                sourceSize.height: root.artSize * Screen.devicePixelRatio
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: art.loadedProgress * root.shownProgress
                visible: opacity > 0

                Behavior on loadedProgress {
                    Anim {
                        duration: Tokens.animDuration.effectsSlow
                    }
                }
            }
        }

        // With no player the text is hidden but keeps its lines' height, and a bar stands in for each.
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - root.artSize - parent.spacing
            height: texts.height

            Column {
                id: texts

                width: parent.width

                MarqueeText {
                    id: titleText

                    width: parent.width
                    opacity: root.shownProgress
                    text: root.shownTitle || " "
                    pixelSize: Tokens.fontSize.sm
                    weight: Tokens.font.semibold
                    color: Theme.color.m3onSurface
                }

                MarqueeText {
                    id: artistText

                    width: parent.width
                    opacity: root.shownProgress
                    text: root.shownArtist || " "
                    pixelSize: Tokens.fontSize.xs
                    color: Theme.color.m3onSurfaceVariant
                }
            }

            TextPlaceholder {
                y: titleText.y + (titleText.height - height) / 2
                opacity: 1 - root.shownProgress
                visible: opacity > 0
            }

            TextPlaceholder {
                y: artistText.y + (artistText.height - height) / 2
                opacity: 1 - root.shownProgress
                visible: opacity > 0
                secondary: true
            }
        }
    }

    Scrubber {
        width: parent.width
        value: MediaService.hasProgress ? MediaService.position / MediaService.length : 0
        interactive: MediaService.canSeek
        glideDuration: root.positionPollInterval
        Accessible.name: "Seek"
        onSeekRequested: value => MediaService.seek(value * MediaService.length)
        onStepRequested: direction => MediaService.seek(MediaService.position + direction * root.seekStep)
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Tokens.spacing.xs

        Button {
            type: "standard"
            buttonHeight: Tokens.bar.iconButtonSize
            iconSize: Tokens.icon.md
            iconFilled: true
            icon: "skip_previous"
            enabled: MediaService.canGoPrevious
            Accessible.name: "Previous"
            onClicked: MediaService.previous()
        }

        Button {
            type: "standard"
            buttonHeight: Tokens.bar.iconButtonSize
            iconSize: Tokens.icon.lg
            iconFilled: true
            icon: MediaService.playing ? "pause" : "play_arrow"
            enabled: MediaService.canTogglePlaying
            Accessible.name: MediaService.playing ? "Pause" : "Play"
            onClicked: MediaService.togglePlaying()
        }

        Button {
            type: "standard"
            buttonHeight: Tokens.bar.iconButtonSize
            iconSize: Tokens.icon.md
            iconFilled: true
            icon: "skip_next"
            enabled: MediaService.canGoNext
            Accessible.name: "Next"
            onClicked: MediaService.next()
        }
    }
}
