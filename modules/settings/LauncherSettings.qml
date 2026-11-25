import QtQuick

SettingsPage {
    id: root

    name: "launcher"
    title: "Launcher"
    icon: "search"
    description: "App search, commands and the symbol picker."
    sections: [
        {
            title: "",
            rows: [
                { type: "text", label: "Command prefix", description: "Typed first in the launcher to run a command, as in >theme.", key: "launcher.commandPrefix", placeholder: ">" },
                { type: "number", label: "Symbol results", description: "Most emoji and glyphs listed for a search.", key: "launcher.maxSymbolResults", min: 1, max: 10000, step: 10 }
            ]
        }
    ]
}
