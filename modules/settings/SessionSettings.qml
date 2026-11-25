import QtQuick

// shortcut: a command is split on spaces, so an argument can't contain one; edit config.json for that.
SettingsPage {
    id: root

    readonly property var commandText: value => Array.isArray(value) ? value.join(" ") : ""
    readonly property var commandValue: text => text.trim() ? text.trim().split(/\s+/) : undefined

    name: "session"
    title: "Session"
    icon: "power_settings_new"
    description: "The commands behind the session menu."
    sections: [
        {
            title: "",
            rows: [
                { type: "text", label: "Lock", description: "Needs a locker that listens to logind.", key: "session.lock", toText: root.commandText, fromText: root.commandValue },
                { type: "text", label: "Restart", key: "session.reboot", toText: root.commandText, fromText: root.commandValue },
                { type: "text", label: "Shut down", key: "session.poweroff", toText: root.commandText, fromText: root.commandValue }
            ]
        }
    ]
}
