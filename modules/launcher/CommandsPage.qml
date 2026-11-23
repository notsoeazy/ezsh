import QtQuick

import "../../utils/fuzzysort.mjs" as Fuzzysort

LauncherPage {
    id: root

    readonly property var commands: [
        {
            title: "clipboard",
            subtitle: "Clipboard history",
            symbol: "content_paste",
            page: "clipboard"
        },
        {
            title: "symbols",
            subtitle: "Emoji, symbols and Nerd Font glyphs",
            symbol: "emoji_symbols",
            page: "symbols"
        }
    ]
    readonly property var index: Fuzzysort.default.snapshot(root.commands, {
        keys: ["title", "subtitle"]
    })

    icon: "terminal"
    emptyText: "No commands found"
    actionHint: "run"

    row: Component {
        EntryRow {
            title: modelData.title
            subtitle: modelData.subtitle
            symbol: modelData.symbol
        }
    }

    function results(query) {
        if (!query)
            return root.commands;
        return Fuzzysort.default.go(query, root.index, {
            limit: 0,
            threshold: 0
        }).map(result => result.obj);
    }

    function activate(entry, launcher) {
        launcher.openPage(entry.page);
    }
}
