import QtQuick
import Quickshell
import Quickshell.Io

// One brightnessctl device: reads its level from sysfs (watched, optionally polled)
// and writes through brightnessctl, one write at a time.
Scope {
    id: root

    property string device: ""
    property string deviceClass: ""
    property int maximum: 1
    // Lowest level set() goes to, e.g. 1 so the screen never goes fully dark.
    property int minimum: 0
    // Firmware hotkeys change some devices without a file event, so read them on a timer too.
    property bool poll: false
    // Change per step(), 0..1.
    property real stepSize: 0.05

    property int raw: 0
    // The level last asked for, shown until the write lands so the value doesn't jump back.
    property int desired: -1
    property int pending: -1

    readonly property bool available: root.device !== ""
    readonly property real value: (root.desired >= 0 ? root.desired : root.raw) / root.maximum

    function attach(device, deviceClass, maximum) {
        root.deviceClass = deviceClass;
        root.maximum = Math.max(1, maximum);
        root.device = device;
    }

    // Level 0..1.
    function set(value) {
        if (!root.available || !isFinite(value))
            return;
        root.desired = Math.max(root.minimum, Math.min(root.maximum, Math.round(value * root.maximum)));
        root.pending = root.desired;
        root.writeNext();
    }

    // One stepSize up (+1) or down (-1).
    function step(direction) {
        root.set(root.value + direction * root.stepSize);
    }

    function writeNext() {
        if (writer.running || root.pending < 0)
            return;
        writer.command = ["brightnessctl", "--quiet", "--device", root.device, "set", String(root.pending)];
        root.pending = -1;
        writer.running = true;
    }

    Process {
        id: writer

        onExited: code => {
            if (code !== 0)
                console.warn("BacklightDevice: brightnessctl failed for", root.device, code);
            if (root.pending >= 0)
                Qt.callLater(root.writeNext);
            else
                reader.reload();
        }
    }

    FileView {
        id: reader

        path: root.available ? `/sys/class/${root.deviceClass}/${root.device}/brightness` : ""
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const level = Number(text().trim());
            if (isFinite(level))
                root.raw = level;
            if (root.pending < 0 && !writer.running)
                root.desired = -1;
        }
    }

    Timer {
        interval: 500
        repeat: true
        running: root.available && root.poll
        onTriggered: reader.reload()
    }
}
