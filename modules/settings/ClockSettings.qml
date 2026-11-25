import QtQuick

SettingsPage {
    id: root

    name: "clock"
    title: "Clock & Date"
    icon: "schedule"
    description: "How the bar and the control panel show the time."
    sections: [
        {
            title: "",
            rows: [
                { type: "switch", label: "24-hour time", key: "clock.use24Hour" },
                { type: "switch", label: "Show seconds", key: "clock.showSeconds" }
            ]
        }
    ]
}
