import QtQuick

// shortcut: a command is split on spaces, so an argument can't contain one; edit config.json for that.
SettingsPage {
    id: root

    readonly property var commandText: value => Array.isArray(value) ? value.join(" ") : ""
    readonly property var commandValue: text => text.trim() ? text.trim().split(/\s+/) : undefined

    name: "session"
    title: "Session"
    icon: "power_settings_new"
    description: "What happens when you step away, and the session commands."
    sections: [
        {
            title: "When idle",
            rows: [
                { type: "number", label: "Lock after", description: "0 never locks. Keep awake and playing video pause all idle timers.", key: "session.lockTimeout", min: 0, max: 86400, step: 60, scale: 60, unit: "min" },
                { type: "number", label: "Screen off after", description: "0 keeps the screens on. Any input turns them back on.", key: "session.screenOffTimeout", min: 0, max: 86400, step: 60, scale: 60, unit: "min" },
                { type: "switch", label: "Screen off while media plays", description: "Locking still happens; suspend never does while media plays.", key: "session.screenOffWhilePlaying" },
                { type: "number", label: "Suspend after", description: "0 never suspends. Not while media plays; the screen locks before sleep.", key: "session.suspendTimeout", min: 0, max: 86400, step: 60, scale: 60, unit: "min" }
            ]
        },
        {
            title: "Commands",
            rows: [
                { type: "text", label: "Suspend", key: "session.suspend", toText: root.commandText, fromText: root.commandValue },
                { type: "text", label: "Restart", key: "session.reboot", toText: root.commandText, fromText: root.commandValue },
                { type: "text", label: "Shut down", key: "session.poweroff", toText: root.commandText, fromText: root.commandValue }
            ]
        }
    ]
}
