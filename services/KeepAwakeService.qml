pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool enabled: false


    function toggle() {
        root.enabled = !root.enabled;
    }
}
