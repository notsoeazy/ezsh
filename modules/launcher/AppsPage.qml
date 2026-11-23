import QtQuick

import qs.services

LauncherPage {
    placeholder: "Search apps"
    emptyText: "No apps found"

    row: Component {
        EntryRow {
            title: modelData.name || ""
            subtitle: modelData.genericName || modelData.comment || ""
            iconName: modelData.icon || ""
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
