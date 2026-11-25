import QtQuick

SettingsPage {
    id: root

    name: "osd"
    title: "On-screen Display"
    icon: "tune"
    description: "The popup in the bar when a level or a mode changes."
    sections: [
        {
            title: "",
            rows: [
                { type: "switch", label: "Show the on-screen display", key: "osd.enabled" },
                { type: "switch", label: "Show over open views", description: "Off holds messages until the launcher or panel closes.", key: "osd.showOverViews" },
                { type: "number", label: "Level duration", description: "Volume and brightness.", key: "osd.levelTimeout", min: 100, max: 60000, step: 100, scale: 1000, unit: "s" },
                { type: "number", label: "Message duration", description: "Modes such as Do Not Disturb.", key: "osd.messageTimeout", min: 100, max: 60000, step: 100, scale: 1000, unit: "s" }
            ]
        },
        {
            title: "Show it for",
            rows: [
                { type: "switch", label: "Volume", key: "osd.showVolume" },
                { type: "switch", label: "Microphone", key: "osd.showMicrophone" },
                { type: "switch", label: "Brightness", key: "osd.showBrightness" },
                { type: "switch", label: "Keyboard brightness", key: "osd.showKeyboardBrightness" },
                { type: "switch", label: "Do Not Disturb", key: "osd.showDoNotDisturb" },
                { type: "switch", label: "Night light", key: "osd.showNightLight" },
                { type: "switch", label: "Keep awake", key: "osd.showKeepAwake" },
                { type: "switch", label: "Power profile", key: "osd.showPowerProfile" },
                { type: "switch", label: "Battery charge limit", key: "osd.showConservationMode" },
                { type: "switch", label: "Screenshots and recordings", key: "osd.showCapture" }
            ]
        }
    ]
}
