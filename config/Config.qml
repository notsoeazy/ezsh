pragma Singleton

import Quickshell
import QtQuick

Singleton {

    readonly property Border border: Border {}
    readonly property Bar bar: Bar {}
    readonly property Osd osd: Osd {}
    readonly property Services services: Services {}

    component Bar: QtObject {
        readonly property int collapsedHeight: 42
        readonly property int expandedHeight: 88
        readonly property int expandedWidth: 520
        readonly property int centerGap: 24
        // false: a notch hanging from the border, with corners curving into it.
        // true: a detached island (pill), floatingGap below the border.
        readonly property bool floating: false
        // Space between the border and a floating island.
        readonly property int floatingGap: 8
        readonly property int cornerRadius: 16
        readonly property int padding: 20
        readonly property int workspaces: 5
        readonly property var specialIcons: ({
            "special": "star",
            "sysmon": "monitor_heart",
            "music": "music_note",
            "communication": "forum",
            "todo": "checklist"
        })
        readonly property int hoverEnterDelay: 60
        readonly property int hoverExitDelay: 200
        readonly property int borderGap: 3
    }

    component Osd: QtObject {
        readonly property bool enabled: true
        // One switch per kind of announcement.
        readonly property bool volume: true
        readonly property bool brightness: true
        readonly property bool keyboardBrightness: true
        readonly property bool microphone: true
        readonly property bool doNotDisturb: true
        readonly property bool nightLight: true
        readonly property bool keepAwake: true
        // Ms a slider / message stays up after the last change.
        readonly property int levelTimeout: 1500
        readonly property int messageTimeout: 2500
        // Ms after startup before anything is announced, so login doesn't flash an OSD.
        readonly property int startupDelay: 2000
        // Whether the OSD may briefly take over an open view (launcher, ...). A view that already
        // shows these controls (the control panel) always hides it.
        readonly property bool overViews: true
    }

    component Services: QtObject {
        // Percent per step: IPC increase/decrease and one mouse-wheel notch on the OSD slider.
        readonly property int volumeStep: 5
        readonly property int brightnessStep: 5
    }

    component Border: QtObject {
        readonly property int thickness: 10
        readonly property int radius: 20
        readonly property int gap: 10
    }

}