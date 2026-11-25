import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.services

// Loaded only while locked. Destroying a WlSessionLock that is still locked leaves the session locked for good, so the
// loader stays active until the compositor has confirmed the unlock (secure drops).
// shortcut: a hot reload while locked resets LockService.locked and unlocks; persist the state if that matters outside development.
Scope {
    id: root

    property bool secure: false

    LazyLoader {
        active: LockService.locked || root.secure

        WlSessionLock {
            id: sessionLock

            locked: LockService.locked
            onSecureChanged: root.secure = sessionLock.secure

            LockSurface {}
        }
    }
}
