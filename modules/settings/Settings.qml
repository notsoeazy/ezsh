import QtQuick
import Quickshell

import qs.services

// The settings window, created only while it is open.
Scope {
    id: root

    LazyLoader {
        active: SettingsService.shown

        SettingsWindow {}
    }
}
