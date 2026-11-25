pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs
import qs.utils

// Image sources for app icons that never decode a large raster in the shell stores in cache so that Qt does not produce warning for large icons.
Singleton {
    id: root

    property var thumbnails: ({})
    property bool ready: false
    property bool rerunQueued: false

    readonly property int thumbnailSize: 64
    readonly property int refreshDelayInterval: 2000
    readonly property var iconNames: DesktopEntries.applications.values.map(app => app.icon).filter(icon => icon)

    function source(name) {
        if (!name)
            return "";
        const thumbnail = root.thumbnails[name];
        if (thumbnail)
            return FilePaths.toFileUrl(thumbnail);
        if (thumbnail === null || root.ready && !(name in root.thumbnails))
            return Quickshell.iconPath(name, true);
        return "";
    }

    function refresh() {
        if (root.iconNames.length === 0)
            return;
        if (generator.running) {
            root.rerunQueued = true;
            return;
        }
        generator.command = ["python3", "-I", Quickshell.shellPath("scripts/icon-thumbs.py"), String(root.thumbnailSize), ...root.iconNames];
        generator.running = true;
    }

    onIconNamesChanged: refreshDelay.restart()
    Component.onCompleted: refreshDelay.restart()

    Timer {
        id: refreshDelay

        interval: root.refreshDelayInterval
        onTriggered: root.refresh()
    }

    Process {
        id: generator

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.thumbnails = JSON.parse(text).icons;
                    root.ready = true;
                } catch (error) {
                    console.warn("IconService: bad output from icon-thumbs.py", error);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    console.warn("IconService:", text.trim());
            }
        }

        onExited: code => {
            if (code !== 0) {
                console.warn("IconService: icon-thumbs.py failed with code", code);
                root.ready = true;
            }
            if (root.rerunQueued) {
                root.rerunQueued = false;
                Qt.callLater(root.refresh);
            }
        }
    }
}
