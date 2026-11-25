pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

import qs
import qs.config
import qs.utils

Singleton {
    id: root

    property bool overlayLoaded: false
    property bool overlayShown: false
    property string kind: "screenshot" // "screenshot" | "record"
    property string mode: "region" // "region" | "window" | "screen"
    property bool recordAudio: false
    property string pointerScreen: ""
    property string ownerScreen: ""
    property var queuedRecording: null
    property bool recordingPaused: false

    readonly property string screenshotDirectory: FilePaths.absolutePath(Config.capture.screenshotDirectory)
    readonly property string recordingDirectory: FilePaths.absolutePath(Config.capture.recordingDirectory)
    readonly property string clipboardImagePath: `${FilePaths.runtime}/ezsh-screenshot.png`
    readonly property bool recording: recorder.running

    function timestamp() {
        return Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss");
    }

    function start(kind) {
        if (root.overlayLoaded || (kind === "record" && root.recording))
            return;
        root.kind = kind === "record" ? "record" : "screenshot";
        if (ViewService.view) {
            ViewService.close();
            openDelay.restart();
        } else {
            root.open();
        }
    }

    function open() {
        HyprlandService.refreshWindows();
        directoryMaker.running = true;
        root.ownerScreen = "";
        root.pointerScreen = HyprlandService.focusedMonitorName;
        root.queuedRecording = null;
        root.overlayLoaded = true;
        root.overlayShown = true;
    }

    function toggleRecording() {
        if (root.recording)
            root.stopRecording();
        else
            root.start("record");
    }

    function setMode(mode) {
        if (["region", "window", "screen"].includes(mode))
            root.mode = mode;
    }

    function setKind(kind) {
        if (kind === "screenshot" || kind === "record")
            root.kind = kind;
    }

    function setRecordAudio(enabled) {
        root.recordAudio = enabled;
    }

    function setPointerScreen(name) {
        root.pointerScreen = name;
    }

    function setOwnerScreen(name) {
        root.ownerScreen = name;
    }

    function cancel() {
        root.overlayShown = false;
    }

    function overlayClosed() {
        if (!root.overlayLoaded || root.overlayShown)
            return;
        root.overlayLoaded = false;
        root.ownerScreen = "";
        if (root.queuedRecording)
            root.startRecording(root.queuedRecording);
        root.queuedRecording = null;
    }

    function record(output, globalRect) {
        root.queuedRecording = { output, rect: globalRect };
        root.overlayShown = false;
    }

    function deliverScreenshot(grabResult, saveToFile) {
        const path = saveToFile ? `${root.screenshotDirectory}/Screenshot_${root.timestamp()}.png` : root.clipboardImagePath;
        root.overlayShown = false;
        if (!grabResult.saveToFile(path)) {
            console.warn("CaptureService: could not write", path);
            return;
        }
        copier.command = ["sh", "-c", "wl-copy --type image/png < \"$1\"", "sh", path];
        copier.running = true;
        OsdService.announce("capture", {
            icon: saveToFile ? "screenshot_region" : "content_copy",
            text: saveToFile ? "Screenshot saved" : "Screenshot copied"
        });
    }

    function startRecording(request) {
        if (root.recording)
            return;
        const r = request.rect;
        const target = r ? ["-w", "region", "-region", `${Math.round(r.width)}x${Math.round(r.height)}+${Math.round(r.x)}+${Math.round(r.y)}`] : ["-w", request.output];
        recorder.path = `${root.recordingDirectory}/Recording_${root.timestamp()}.mp4`;
        recorder.command = ["gpu-screen-recorder", ...target, "-f", String(Config.capture.recordFrameRate), ...(root.recordAudio ? ["-a", "default_output"] : []), "-o", recorder.path];
        root.recordingPaused = false;
        recorder.running = true;
    }

    function stopRecording() {
        // SIGINT makes gpu-screen-recorder finish writing the file.
        if (root.recording)
            recorder.signal(2);
    }

    function togglePause() {
        if (!root.recording)
            return;
        // SIGUSR2 toggles gpu-screen-recorder between paused and recording.
        recorder.signal(12);
        root.recordingPaused = !root.recordingPaused;
        OsdService.announce("capture", {
            icon: root.recordingPaused ? "pause_circle" : "videocam",
            text: root.recordingPaused ? "Recording paused" : "Recording resumed"
        });
    }

    // qs ipc call capture screenshot
    IpcHandler {
        target: "capture"

        function screenshot(): void {
            root.start("screenshot");
        }

        function record(): void {
            root.toggleRecording();
        }

        function stop(): void {
            root.stopRecording();
        }

        function pause(): void {
            root.togglePause();
        }

        function cancel(): void {
            root.cancel();
        }
    }

    GlobalShortcut {
        appid: "ezsh"
        name: "screenshot"
        description: "Take a screenshot"
        onPressed: root.start("screenshot")
    }

    GlobalShortcut {
        appid: "ezsh"
        name: "record"
        description: "Start or stop a screen recording"
        onPressed: root.toggleRecording()
    }

    Timer {
        id: openDelay

        interval: Tokens.animDuration.spatialSlow
        onTriggered: root.open()
    }

    Process {
        id: directoryMaker

        command: ["mkdir", "-p", root.screenshotDirectory, root.recordingDirectory]
        onExited: code => {
            if (code !== 0)
                console.warn("CaptureService: mkdir failed with code", code);
        }
    }

    Process {
        id: copier

        onExited: code => {
            if (code !== 0)
                console.warn("CaptureService: wl-copy failed with code", code);
        }
    }

    Process {
        id: recorder

        property string path: ""

        stderr: StdioCollector {
            id: recorderErrors
        }

        onExited: code => {
            root.recordingPaused = false;
            if (code === 0) {
                OsdService.announce("capture", { icon: "videocam", text: "Recording saved" });
            } else {
                console.warn("CaptureService: gpu-screen-recorder failed with code", code, recorderErrors.text);
                OsdService.announce("capture", { icon: "videocam_off", text: "Recording failed" });
            }
        }
    }
}
