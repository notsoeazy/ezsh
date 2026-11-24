pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Singleton {
    id: root

    readonly property var items: SystemTray.items.values.filter(i => i.status !== Status.Passive)

    function iconSource(item) {
        const icon = item?.icon ?? "";
        const prefix = "image://icon/";
        if (!icon.startsWith(prefix) || icon.includes("?path="))
            return icon;
        return Quickshell.iconPath(icon.slice(prefix.length), true);
    }

    function activate(item) {
        item?.activate();
    }

    function secondaryActivate(item) {
        item?.secondaryActivate();
    }
}
