import QtQuick

import qs
import qs.components

Loader {
    id: root

    required property Item host
    required property string name

    readonly property bool shown: root.host.displayedView === root.name && !root.host.leaving

    active: root.host.requestedView === root.name || root.host.displayedView === root.name || root.opacity > 0
    asynchronous: true

    opacity: root.shown && root.status === Loader.Ready ? 1 : 0
    visible: root.opacity > 0
    focus: root.shown

    onStatusChanged: {
        if (root.status === Loader.Ready)
            root.host.scheduleSwitch();
    }

    Behavior on opacity {
        Anim {
            duration: Tokens.animDuration.effectsFast
        }
    }
}
