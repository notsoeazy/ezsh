import QtQuick

import qs.services
import qs.modules.launcher.widgets

LauncherPage {
    id: root

    placeholder: "Search apps"
    emptyText: "No apps found"

    row: Component {
        EntryRow {
            id: entryRow

            title: entryRow.modelData.name || ""
            subtitle: entryRow.modelData.genericName || entryRow.modelData.comment || ""
            iconName: entryRow.modelData.icon || ""
        }
    }

    function results(query) {
        return AppService.search(query);
    }

    function activate(entry, launcher) {
        AppService.launch(entry);
        launcher.close();
    }
}
