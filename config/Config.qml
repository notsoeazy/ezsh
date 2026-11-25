pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.utils

// User settings, kept in $XDG_CONFIG_HOME/ezsh/config.json. The values below are the defaults: the
// file is created with every key on first run, a key missing from it keeps its value, edits to it
// apply live, and the settings window writes changes back.
Singleton {
    id: root

    readonly property string path: `${FilePaths.config}/config.json`
    // False while config.json doesn't parse: values keep what they were and nothing is written over the file.
    readonly property bool writable: configState.parsed
    // Ms to gather changes (a dragged slider) into one write.
    readonly property int saveDelay: 300

    readonly property Bar bar: adapter.bar
    readonly property Border border: adapter.border
    readonly property Clock clock: adapter.clock
    readonly property Osd osd: adapter.osd
    readonly property Services services: adapter.services
    readonly property Launcher launcher: adapter.launcher
    readonly property Wallpaper wallpaper: adapter.wallpaper
    readonly property Theming theme: adapter.theme
    readonly property NightLight nightLight: adapter.nightLight
    readonly property Session session: adapter.session
    readonly property Capture capture: adapter.capture

    function checkFile() {
        const text = configFile.text();
        try {
            if (text.trim() !== "")
                JSON.parse(text);
            configState.parsed = true;
        } catch (error) {
            configState.parsed = false;
            console.warn("Config: bad config.json, not saving changes until it is fixed:", error);
        }
    }

    // Read while Config is created, so nothing binds to a default first and then jumps (as in Theme).
    Component.onCompleted: root.checkFile()

    QtObject {
        id: configState

        property bool parsed: true
    }

    FileView {
        id: configFile

        path: root.path
        watchChanges: true
        printErrors: false
        blockLoading: true

        // Not while a save is pending: reloading the previous save would undo the newer change.
        onFileChanged: {
            if (!saveTimer.running)
                configFile.reload();
        }
        onLoaded: root.checkFile()
        onLoadFailed: error => {
            // Later: writing from inside the failed blocking read drops an operation and warns.
            if (error === FileViewError.FileNotFound)
                Qt.callLater(() => configFile.writeAdapter());
        }
        // Only changes made from QML (the settings window) land here, not loads.
        onAdapterUpdated: saveTimer.restart()
        onSaveFailed: error => console.warn("Config: writing", root.path, "failed:", FileViewError.toString(error))

        JsonAdapter {
            id: adapter

            property Bar bar: Bar {}
            property Border border: Border {}
            property Clock clock: Clock {}
            property Osd osd: Osd {}
            property Services services: Services {}
            property Launcher launcher: Launcher {}
            property Wallpaper wallpaper: Wallpaper {}
            property Theming theme: Theming {}
            property NightLight nightLight: NightLight {}
            property Session session: Session {}
            property Capture capture: Capture {}
        }
    }

    Timer {
        id: saveTimer

        interval: root.saveDelay
        onTriggered: {
            if (root.writable)
                configFile.writeAdapter();
        }
    }

    component Bar: JsonObject {
        property bool symmetricSides: true
        property int expandedWidth: 520
        property int dashboardWidth: 640
        property bool floating: false
        property int floatingGap: 8
        property int cornerRadius: 16
        property int workspacesPerPage: 5
        property var specialIcons: ({
            "special": "star",
            "sysmon": "monitor_heart",
            "music": "music_note",
            "communication": "forum",
            "todo": "checklist"
        })
        property int hoverEnterDelay: 60
        property int hoverExitDelay: 200
        property int borderGap: 10
        property string dashboardMode: "auto" // "always" | "auto"
    }

    component Border: JsonObject {
        property int thickness: 10
        property int radius: 20
        property int gap: 0
    }

    component Clock: JsonObject {
        property bool use24Hour: false
        property bool showSeconds: false
    }

    component Osd: JsonObject {
        property int startupDelay: 2000
        property bool enabled: true
        property bool showVolume: true
        property bool showBrightness: true
        property bool showKeyboardBrightness: true
        property bool showMicrophone: true
        property bool showDoNotDisturb: true
        property bool showNightLight: true
        property bool showKeepAwake: true
        property bool showPowerProfile: true
        property bool showConservationMode: true
        property bool showCapture: true
        property int levelTimeout: 1500
        property int messageTimeout: 2500
        property bool showOverViews: true
    }

    component Services: JsonObject {
        property int volumeStepPercent: 5
        property int brightnessStepPercent: 5
    }

    component Launcher: JsonObject {
        property string commandPrefix: ">"
        property int maxSymbolResults: 100
    }

    component Wallpaper: JsonObject {
        property bool enabled: true
        property string directory: "~/Pictures/Wallpapers"
        // Ms to wait after a change before decoding the new wallpaper, so fast browsing skips images.
        property int previewDelay: 120
    }

    component Theming: JsonObject {
        // Where the Hyprland, terminal and GTK color files go (hypr/colors.lua, kitty/colors.conf, ...).
        // "" keeps them in $XDG_STATE_HOME/ezsh/generated; "~/.config" writes them next to each app's config.
        property string outputDirectory: ""
    }

    component NightLight: JsonObject {
        property int temperature: 4300
    }

    component Session: JsonObject {
        // Idle seconds, 0 = off.
        property int lockTimeout: 300
        property int screenOffTimeout: 600
        property int suspendTimeout: 900
        property bool screenOffWhilePlaying: false
        property var suspend: ["systemctl", "suspend"]
        property var reboot: ["systemctl", "reboot"]
        property var poweroff: ["systemctl", "poweroff"]
    }

    component Capture: JsonObject {
        property string screenshotDirectory: "~/Pictures/Screenshots"
        property string recordingDirectory: "~/Videos/Recordings"
        property int recordFrameRate: 60
        property var annotationColors: ["#f43f5e", "#f59e0b", "#22c55e", "#3b82f6", "#ffffff", "#18181b"]
    }
}
