pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.config

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string directory: Config.wallpaper.directory.replace(/^~(?=\/|$)/, root.home)
    readonly property int thumbnailWidth: 480
    readonly property int thumbnailHeight: 270
    readonly property string current: !root.stateRead ? "" : root.images.includes(root.saved) ? root.saved : (root.images[0] ?? "")
    readonly property string showing: root.preview || root.current

    // Qt's default image allocation limit; larger images get a screen-sized copy from the script.
    readonly property real decodeLimit: 256 * 1024 * 1024
    // Bytes per decoded pixel: Qt decodes 16-bit PNGs to 8 (RGBA64), so assume the worst case.
    readonly property int decodeBytesPerPixel: 8

    property list<string> images: []
    property var sizes: ({})
    property var thumbnails: ({})
    property var fitted: ({})
    property var fitQueue: []
    property string preview: ""
    property string saved: ""
    property bool stateRead: false
    // A thumbnail run was asked for while one was busy; run again when it ends (new images since).
    property bool thumbnailRerunQueued: false

    function fileUrl(path) {
        return "file://" + path.split("/").map(encodeURIComponent).join("/");
    }

    function setPreview(path) {
        if (root.images.includes(path))
            root.preview = path;
    }

    function clearPreview() {
        root.preview = "";
    }

    function set(path) {
        if (!root.images.includes(path))
            return;
        root.saved = path;
        root.preview = "";
        stateFile.setText(path);
    }

    function needsFit(path) {
        const d = root.sizes[path];
        return !!d && d[0] * d[1] * root.decodeBytesPerPixel > root.decodeLimit;
    }

    function fitKey(path, size) {
        return `${path}@${Math.ceil(size.width)}x${Math.ceil(size.height)}`;
    }

    function source(path, size) {
        if (!path)
            return "";
        if (!root.needsFit(path))
            return root.fileUrl(path);
        return root.fitted[root.fitKey(path, size)] ?? "";
    }

    function prepare(path, size) {
        const key = root.fitKey(path, size);
        if (!root.needsFit(path) || key in root.fitted || root.fitQueue.includes(key))
            return;
        root.fitQueue = root.fitQueue.concat([key]);
        root.fitNext();
    }

    function fitNext() {
        if (fitter.running || root.fitQueue.length === 0)
            return;
        const key = root.fitQueue[0];
        const at = key.lastIndexOf("@");
        const [width, height] = key.slice(at + 1).split("x");
        fitter.key = key;
        fitter.command = ["python3", "-I", Quickshell.shellPath("scripts/wallpapers.py"), "fit", width, height, key.slice(0, at)];
        fitter.running = true;
    }

    function refresh() {
        if (!scanner.running)
            scanner.running = true;
    }


    function makeThumbnails() {
        if (thumbnailer.running) {
            root.thumbnailRerunQueued = true;
            return;
        }
        const center = Math.max(0, root.images.indexOf(root.showing));
        const order = root.images.map((path, index) => ({ path, distance: Math.abs(index - center) }))
            .sort((a, b) => a.distance - b.distance)
            .map(entry => entry.path);
        thumbnailer.command = ["python3", "-I", Quickshell.shellPath("scripts/wallpapers.py"), "thumbs", String(root.thumbnailWidth), String(root.thumbnailHeight), ...order];
        thumbnailer.running = true;
    }

    onDirectoryChanged: {
        root.thumbnails = {};
        root.refresh();
    }

    FileView {
        id: stateFile

        path: `${Quickshell.env("XDG_STATE_HOME") || root.home + "/.local/state"}/ezsh/wallpaper`
        atomicWrites: true
        printErrors: false

        onLoaded: {
            root.saved = stateFile.text().trim();
            root.stateRead = true;
        }
        onLoadFailed: root.stateRead = true
        onSaveFailed: error => console.warn("WallpaperService: could not save the wallpaper:", FileViewError.toString(error))
    }

    Process {
        id: scanner

        command: ["python3", "-I", Quickshell.shellPath("scripts/wallpapers.py"), "scan", root.directory]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text);
                    root.sizes = result.sizes;
                    if (JSON.stringify(result.images) !== JSON.stringify(root.images))
                        root.images = result.images;
                } catch (error) {
                    console.warn("WallpaperService: bad output from wallpapers.py", error);
                }
            }
        }

        stderr: ScriptErrors {}

        onExited: code => {
            if (code !== 0)
                console.warn("WallpaperService: scanning", root.directory, "failed", code);
            else
                root.makeThumbnails();
        }
    }

    Process {
        id: thumbnailer

        stdout: SplitParser {
            onRead: line => {
                try {
                    const [path, thumbnail] = JSON.parse(line);
                    const url = thumbnail ? root.fileUrl(thumbnail) : "";
                    if (root.thumbnails[path] !== url)
                        root.thumbnails = Object.assign({}, root.thumbnails, {
                            [path]: url
                        });
                } catch (error) {
                    console.warn("WallpaperService: bad thumbnail line", line);
                }
            }
        }

        stderr: ScriptErrors {}

        onExited: code => {
            if (code !== 0)
                console.warn("WallpaperService: making thumbnails failed", code);
            if (root.thumbnailRerunQueued) {
                root.thumbnailRerunQueued = false;
                Qt.callLater(root.makeThumbnails);
            }
        }
    }

    Process {
        id: fitter

        property string key: ""

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.fitted = Object.assign({}, root.fitted, {
                        [fitter.key]: root.fileUrl(JSON.parse(text))
                    });
                } catch (error) {}
            }
        }

        stderr: ScriptErrors {}

        onExited: code => {
            if (code !== 0) {
                console.warn("WallpaperService: could not resize", fitter.key);
                root.fitted = Object.assign({}, root.fitted, {
                    [fitter.key]: ""
                });
            }
            root.fitQueue = root.fitQueue.slice(1);
            Qt.callLater(root.fitNext);
        }
    }

    component ScriptErrors: StdioCollector {
        onStreamFinished: {
            if (text.trim())
                console.warn("WallpaperService:", text.trim());
        }
    }
}
