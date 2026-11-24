import QtQuick

import qs
import qs.components

// Loads one control panel page while it is current and keeps it until its fade-out reaches 0
Loader {
    id: root

    required property string name
    required property string currentPage
    // The panel is open (not closing).
    required property bool open

    readonly property bool current: root.currentPage === root.name
    readonly property int slideDistance: Tokens.spacing.xxxl

    property real progress: root.current ? 1 : 0

    signal pageRequested(string name)
    signal backRequested()
    signal navigateRequested(string view)

    active: root.current || root.progress > 0
    x: (1 - root.progress) * root.slideDistance * (root.name === "home" ? -1 : 1)
    opacity: root.progress
    visible: root.progress > 0
    enabled: root.current

    onLoaded: {
        root.item.active = Qt.binding(() => root.current);
        root.item.shown = Qt.binding(() => root.current && root.open);
    }

    Behavior on progress {
        Anim {
            duration: Tokens.animDuration.spatialFast
        }
    }

    Connections {
        target: root.item
        ignoreUnknownSignals: true

        function onPageRequested(name) {
            root.pageRequested(name);
        }

        function onBackRequested() {
            root.backRequested();
        }

        function onNavigateRequested(view) {
            root.navigateRequested(view);
        }
    }
}
