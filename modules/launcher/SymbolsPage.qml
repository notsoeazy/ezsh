import QtQuick

import qs.services
import qs.modules.launcher.widgets

LauncherPage {
    id: root

    placeholder: "Search emoji and symbols"
    icon: "emoji_symbols"
    emptyText: "Nothing found"
    actionHint: "copy"

    row: Component {
        EntryRow {
            id: entryRow

            title: entryRow.modelData.title
            subtitle: entryRow.modelData.group
            glyph: entryRow.modelData.glyph
            nerdGlyph: entryRow.modelData.nerd
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
