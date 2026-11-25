pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property Bar bar: Bar {}
    readonly property Border border: Border {}
    readonly property Osd osd: Osd {}
    readonly property Services services: Services {}
    readonly property Launcher launcher: Launcher {}
    readonly property Wallpaper wallpaper: Wallpaper {}
    readonly property Theming theme: Theming {}
    readonly property NightLight nightLight: NightLight {}
    readonly property Session session: Session {}
    readonly property Capture capture: Capture {}

    component Bar: QtObject {
        readonly property bool symmetricSides: true
        readonly property int expandedWidth: 520
        readonly property int dashboardWidth: 640
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
        readonly property int borderGap: 10
        readonly property string dashboardMode: "auto"
    }

    component Border: QtObject {
        readonly property int thickness: 10
        readonly property int radius: 20
        readonly property int gap: 0
    }

    component Osd: QtObject {
        readonly property int startupDelay: 2000
        readonly property bool enabled: true
        readonly property bool showVolume: true
        readonly property bool showBrightness: true
        readonly property bool showKeyboardBrightness: true
        readonly property bool showMicrophone: true
        readonly property bool showDoNotDisturb: true
        readonly property bool showNightLight: true
        readonly property bool showKeepAwake: true
        readonly property bool showPowerProfile: true
        readonly property bool showConservationMode: true
        readonly property bool showCapture: true
        readonly property int levelTimeout: 1500
        readonly property int messageTimeout: 2500
        readonly property bool showOverViews: true
    }

    component Services: QtObject {
        readonly property int volumeStepPercent: 5
        readonly property int brightnessStepPercent: 5
    }

    component Launcher: QtObject {
        readonly property string commandPrefix: ">"
        readonly property int maxSymbolResults: 100
        readonly property int symbolIndexTimeout: 30000
    }

    component Wallpaper: QtObject {
        readonly property bool enabled: true
        readonly property string directory: "~/Pictures/Wallpapers"
        // Ms to wait after a change before decoding the new wallpaper, so fast browsing skips images.
        readonly property int previewDelay: 120
    }

    component Theming: QtObject {
        // Where the Hyprland, terminal and GTK color files go (hypr/colors.lua, kitty/colors.conf, ...).
        // "" keeps them in $XDG_STATE_HOME/ezsh/generated; "~/.config" writes them next to each app's config.
        readonly property string outputDirectory: ""
    }

    component NightLight: QtObject {
        readonly property int temperature: 4300
    }

    component Session: QtObject {
        readonly property var lock: ["loginctl", "lock-session"]
        readonly property var reboot: ["systemctl", "reboot"]
        readonly property var poweroff: ["systemctl", "poweroff"]
    }

    component Capture: QtObject {
        readonly property string screenshotDirectory: "~/Pictures/Screenshots"
        readonly property string recordingDirectory: "~/Videos/Recordings"
        readonly property int recordFrameRate: 60
        readonly property var annotationColors: ["#f43f5e", "#f59e0b", "#22c55e", "#3b82f6", "#ffffff", "#18181b"]
    }
}
