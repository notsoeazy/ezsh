import QtQuick

import qs
import qs.themes
import qs.services
import qs.components

// A breathing red dot while the screen is being captured; takes no space otherwise. For an ezsh
// recording, clicking it opens a menu to pause, resume or stop, so a stray click never ends it.
Reveal {
    id: root

    readonly property bool menuOpen: menu.shown
    readonly property bool paused: CaptureService.recordingPaused

    revealed: HyprlandService.screencasting || CaptureService.recording
    leadingGap: Tokens.spacing.md

    onPausedChanged: dot.opacity = 1

    StyledRectangle {
        id: dot

        implicitWidth: Tokens.bar.workspaceDotSize
        implicitHeight: Tokens.bar.workspaceDotSize
        radius: Tokens.radius.full
        color: root.paused ? Theme.color.m3outline : Theme.color.m3error

        Accessible.role: Accessible.Button
        Accessible.name: "Recording options"
        Accessible.onPressAction: menu.toggle(dot)

        MouseArea {
            anchors.fill: parent
            anchors.margins: -Tokens.spacing.xs
            enabled: CaptureService.recording
            cursorShape: Qt.PointingHandCursor
            onClicked: menu.toggle(dot)
        }

        SequentialAnimation on opacity {
            running: root.visible && !root.paused
            loops: Animation.Infinite

            Anim {
                to: 0.35
                duration: Tokens.animDuration.spatialSlow * 2
                easing.type: Easing.InOutSine
            }
            Anim {
                to: 1
                duration: Tokens.animDuration.spatialSlow * 2
                easing.type: Easing.InOutSine
            }
        }
    }

    Menu {
        id: menu

        leftAligned: true
        containerColor: Theme.color.m3background

        MenuItem {
            icon: root.paused ? "play_arrow" : "pause"
            text: root.paused ? "Resume recording" : "Pause recording"
            onClicked: {
                CaptureService.togglePause();
                menu.close();
            }
        }

        MenuItem {
            icon: "stop"
            text: "Stop recording"
            onClicked: {
                CaptureService.stopRecording();
                menu.close();
            }
        }
    }

    Connections {
        target: CaptureService

        function onRecordingChanged() {
            if (!CaptureService.recording)
                menu.close();
        }
    }
}
