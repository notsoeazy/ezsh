import QtQuick

SettingsPage {
    id: root

    name: "bar"
    title: "Bar"
    icon: "toolbar"
    description: "The bar's shape, what it shows when expanded, and the screen border."
    sections: [
        {
            title: "Layout",
            rows: [
                { type: "switch", label: "Floating bar", description: "Detach the bar from the top edge.", key: "bar.floating" },
                { type: "number", label: "Floating gap", description: "Space above a floating bar.", key: "bar.floatingGap", min: 0, max: 200, step: 1, unit: "px" },
                { type: "number", label: "Corner radius", key: "bar.cornerRadius", min: 0, max: 200, step: 1, unit: "px" },
                { type: "switch", label: "Keep the clock centered", description: "Give both sides the width of the wider one.", key: "bar.symmetricSides" },
                { type: "number", label: "Expanded width", key: "bar.expandedWidth", min: 200, max: 4000, step: 10, unit: "px" }
            ]
        },
        {
            title: "Dashboard",
            rows: [
                {
                    type: "choice",
                    label: "Show the dashboard",
                    description: "Tray, media and notifications under the expanded bar.",
                    key: "bar.dashboardMode",
                    options: [{ label: "Always", value: "always" }, { label: "With activity", value: "auto" }]
                },
                { type: "number", label: "Dashboard width", key: "bar.dashboardWidth", min: 200, max: 4000, step: 10, unit: "px" }
            ]
        },
        {
            title: "Hover",
            rows: [
                { type: "number", label: "Expand delay", description: "How long the pointer rests on the bar before it expands.", key: "bar.hoverEnterDelay", min: 0, max: 10000, step: 10, unit: "ms" },
                { type: "number", label: "Collapse delay", description: "How long the bar stays open after the pointer leaves.", key: "bar.hoverExitDelay", min: 0, max: 10000, step: 10, unit: "ms" }
            ]
        },
        {
            title: "Workspaces",
            rows: [
                { type: "number", label: "Workspaces per page", key: "bar.workspacesPerPage", min: 1, max: 100, step: 1 }
            ]
        },
        {
            title: "Screen border",
            rows: [
                { type: "number", label: "Thickness", key: "border.thickness", min: 0, max: 200, step: 1, unit: "px" },
                { type: "number", label: "Corner radius", key: "border.radius", min: 0, max: 200, step: 1, unit: "px" },
                { type: "number", label: "Gap beside windows", description: "Extra space windows keep from the border.", key: "border.gap", min: 0, max: 200, step: 1, unit: "px" },
                { type: "number", label: "Gap under the bar", description: "Space windows keep below the bar.", key: "bar.borderGap", min: 0, max: 200, step: 1, unit: "px" }
            ]
        }
    ]
}
