import QtQuick
import Quickshell

import qs.services

// The screenshot / recording overlay: one CaptureWindow per screen, created only while capturing.
Scope {
    id: root

    LazyLoader {
        active: CaptureService.overlayLoaded

        Variants {
            model: Quickshell.screens

            CaptureWindow {}
        }
    }
}
