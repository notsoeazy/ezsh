import QtQuick

import qs.services

LauncherPage {
    placeholder: "Search emoji and symbols"
    icon: "emoji_symbols"
    emptyText: "Nothing found"
    actionHint: "copy"

    row: Component {
        EntryRow {
            title: modelData.title
            subtitle: modelData.group
            glyph: modelData.glyph
            nerdGlyph: modelData.nerd
        }
    }

    function results(query) {
        return SymbolService.search(query);
    }

    function activate(entry, launcher) {
        ClipboardService.copyText(entry.glyph);
        launcher.close();
    }
}
