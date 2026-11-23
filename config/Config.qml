pragma Singleton

import Quickshell
import QtQuick

Singleton {

    readonly property Border border: Border {}
    readonly property Bar bar: Bar {}
    readonly property Osd osd: Osd {}
    readonly property Services services: Services {}

    component Bar: QtObject {
        readonly property int expandedWidth: 520
        readonly property bool floating: false
        readonly property int floatingGap: 8
        readonly property int cornerRadius: 16
        readonly property int workspacesPerPage: 5
        readonly property var specialIcons: ({
            "special": "star",
            "sysmon": "monitor_heart",
            "music": "music_note",
            "communication": "forum",
            "todo": "checklist"
        })
        readonly property int hoverEnterDelay: 60
        readonly property int hoverExitDelay: 200
        readonly property int borderGap: 0
    }

    component Osd: QtObject {
        readonly property bool enabled: true
        readonly property bool showVolume: true
        readonly property bool showBrightness: true
        readonly property bool showKeyboardBrightness: true
        readonly property bool showMicrophone: true
        readonly property bool showDoNotDisturb: true
        readonly property bool showNightLight: true
        readonly property bool showKeepAwake: true
        readonly property int levelTimeout: 1500
        readonly property int messageTimeout: 2500
        readonly property bool showOverViews: true
    }

    component Services: QtObject {
        readonly property int volumeStepPercent: 5
        readonly property int brightnessStepPercent: 5
    }

    component Border: QtObject {
        readonly property int thickness: 10
        readonly property int radius: 20
        readonly property int gap: 0
    }
}