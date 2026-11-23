import QtQuick
import Quickshell
import Quickshell.Io

// One brightnessctl device: reads its level from sysfs (watched, optionally polled)
// and writes through brightnessctl, one write at a time.
Scope {
    id: root

    property string deviceName: ""
    property string deviceClass: ""
    property int maxRaw: 1
    property int minRaw: 0
    property bool pollForChanges: false
    property real stepFraction: 0.05

    property int rawLevel: 0
    property int requestedRaw: -1
    property int queuedRaw: -1

    readonly property bool available: root.deviceName !== ""
    readonly property real level: (root.requestedRaw >= 0 ? root.requestedRaw : root.rawLevel) / root.maxRaw

    function useDevice(name, deviceClass, maxRaw) {
        root.deviceClass = deviceClass;
        root.maxRaw = Math.max(1, maxRaw);
        root.deviceName = name;
    }

    // Level 0..1.
    function setLevel(value) {
        if (!root.available || !isFinite(value))
            return;
        root.requestedRaw = Math.max(root.minRaw, Math.min(root.maxRaw, Math.round(value * root.maxRaw)));
        root.queuedRaw = root.requestedRaw;
        root.writeQueuedLevel();
    }

    // One stepFraction up (+1) or down (-1).
    function stepLevel(direction) {
        root.setLevel(root.level + direction * root.stepFraction);
    }

    function writeQueuedLevel() {
        if (brightnessctlWriter.running || root.queuedRaw < 0)
            return;
        brightnessctlWriter.command = ["brightnessctl", "--quiet", "--device", root.deviceName, "set", String(root.queuedRaw)];
        root.queuedRaw = -1;
        brightnessctlWriter.running = true;
    }

    Process {
        id: brightnessctlWriter

        onExited: code => {
            if (code !== 0)
                console.warn("BacklightDevice: brightnessctl failed for", root.deviceName, code);
            if (root.queuedRaw >= 0)
                Qt.callLater(root.writeQueuedLevel);
            else
                sysfsReader.reload();
        }
    }

    FileView {
        id: sysfsReader

        path: root.available ? `/sys/class/${root.deviceClass}/${root.deviceName}/brightness` : ""
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const parsed = Number(text().trim());
            if (isFinite(parsed))
                root.rawLevel = parsed;
            if (root.queuedRaw < 0 && !brightnessctlWriter.running)
                root.requestedRaw = -1;
        }
    }

    Timer {
        interval: 500
        repeat: true
        running: root.available && root.pollForChanges
        onTriggered: sysfsReader.reload()
    }
}
