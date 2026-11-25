import QtQuick

SettingsPage {
    id: root

    name: "capture"
    title: "Capture"
    icon: "screenshot_region"
    description: "Where screenshots and recordings are saved."
    sections: [
        {
            title: "",
            rows: [
                { type: "text", label: "Screenshot folder", key: "capture.screenshotDirectory", placeholder: "~/Pictures/Screenshots" },
                { type: "text", label: "Recording folder", key: "capture.recordingDirectory", placeholder: "~/Videos/Recordings" },
                { type: "number", label: "Recording frame rate", key: "capture.recordFrameRate", min: 1, max: 500, step: 5, unit: "fps" }
            ]
        }
    ]
}
