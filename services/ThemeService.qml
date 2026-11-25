pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.config
import qs.themes
import qs.utils

// The chosen color theme and light/dark mode. scripts/theme.py turns them into colors.json (read
// by Theme) and the Hyprland, terminal and GTK color files; selectors preview without writing.
// Nothing creates it at startup: the applied colors are already in colors.json, and WallpaperService
// calls in when the wallpaper changes.
Singleton {
    id: root

    // [{id, name, light, preview: {dark, light}}] from theme.py, refreshed when a selector opens.
    property var themes: []
    property string current: "default"
    property string mode: "dark"
    property var queuedPreview: null
    property bool applyQueued: false
    property int previewGeneration: 0
    property var applied: ({ theme: "default", mode: "dark" })

    readonly property string script: Quickshell.shellPath("scripts/theme.py")
    readonly property string outputDirectory: Config.theme.outputDirectory ? FilePaths.absolutePath(Config.theme.outputDirectory) : `${FilePaths.state}/generated`
    readonly property bool dynamic: root.current === "dynamic"
    readonly property bool applying: applier.running || root.applyQueued

    function refresh() {
        if (!lister.running)
            lister.running = true;
    }

    function preview(themeId, mode) {
        const request = {
            theme: themeId,
            mode: mode,
            wallpaper: WallpaperService.showing,
            generation: root.previewGeneration
        };
        if (previewer.running)
            root.queuedPreview = request;
        else
            root.runPreview(request);
    }

    function clearPreview() {
        root.queuedPreview = null;
        root.previewGeneration += 1;
        if (!root.applying)
            Theme.setPreview(null);
    }

    function set(themeId, mode) {
        root.current = themeId;
        root.mode = mode === "light" ? "light" : "dark";
        root.apply();
    }

    // Flips what is on screen; a theme without a light palette stays dark.
    function toggleMode() {
        root.set(root.current, Theme.dark ? "light" : "dark");
    }

    function wallpaperChanged() {
        if (root.dynamic)
            root.apply();
    }

    function wallpaperPreviewChanged() {
        if (!root.dynamic)
            return;
        if (WallpaperService.preview)
            root.preview("dynamic", root.mode);
        else
            root.clearPreview();
    }

    function readState() {
        const text = stateFile.text();
        if (!text)
            return;
        try {
            const state = JSON.parse(text);
            root.current = state.theme || "default";
            root.mode = state.mode === "light" ? "light" : "dark";
            root.applied = { theme: root.current, mode: root.mode };
        } catch (error) {
            console.warn("ThemeService: bad theme state, using the default", error);
        }
    }

    function apply() {
        if (applier.running) {
            root.applyQueued = true;
            return;
        }
        applier.request = { theme: root.current, mode: root.mode };
        applier.command = ["python3", "-I", root.script, "apply", root.current, root.mode, WallpaperService.current, root.outputDirectory, Theme.colorsPath];
        applier.running = true;
    }

    function runPreview(request) {
        previewer.request = request;
        previewer.command = ["python3", "-I", root.script, "colors", request.theme, request.mode, request.wallpaper];
        previewer.running = true;
    }

    Component.onCompleted: root.readState()

    FileView {
        id: stateFile

        path: `${FilePaths.state}/theme`
        atomicWrites: true
        printErrors: false
        blockLoading: true
        onSaveFailed: error => console.warn("ThemeService: could not save the theme:", FileViewError.toString(error))
    }

    Process {
        id: lister

        command: ["python3", "-I", root.script, "list", WallpaperService.current]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.themes = JSON.parse(text);
                } catch (error) {
                    console.warn("ThemeService: bad output from theme.py list", error);
                }
            }
        }

        stderr: ScriptErrors {}

        onExited: code => {
            if (code !== 0)
                console.warn("ThemeService: theme.py list failed with code", code);
        }
    }

    Process {
        id: previewer

        property var request: null

        stdout: StdioCollector {
            onStreamFinished: {
                if (previewer.request?.generation !== root.previewGeneration)
                    return;
                try {
                    Theme.setPreview(JSON.parse(text));
                } catch (error) {
                    console.warn("ThemeService: bad output from theme.py colors", error);
                }
            }
        }

        stderr: ScriptErrors {}

        onExited: code => {
            if (code !== 0)
                console.warn("ThemeService: previewing", previewer.request?.theme, "failed with code", code);
            const next = root.queuedPreview;
            root.queuedPreview = null;
            if (next && next.generation === root.previewGeneration)
                Qt.callLater(root.runPreview, next);
        }
    }

    Process {
        id: applier

        // The choice this run applies; current may move on while it runs.
        property var request: null

        stdout: StdioCollector {
            onStreamFinished: {
                // Taken at once instead of waiting for Theme to read colors.json back.
                try {
                    Theme.setApplied(JSON.parse(text));
                } catch (error) {
                    console.warn("ThemeService: bad output from theme.py apply", error);
                }
            }
        }

        stderr: ScriptErrors {}

        onExited: code => {
            if (code === 0) {
                root.applied = applier.request;
                stateFile.setText(JSON.stringify(root.applied));
            } else {
                console.warn("ThemeService: applying", applier.request?.theme, "failed with code", code);
            }
            // A newer choice is waiting; it runs now and decides what stays.
            if (root.applyQueued) {
                root.applyQueued = false;
                Qt.callLater(root.apply);
                return;
            }
            if (code !== 0) {
                root.current = root.applied.theme;
                root.mode = root.applied.mode;
            }
            Theme.setPreview(null);
            root.previewGeneration += 1;
        }
    }

    component ScriptErrors: StdioCollector {
        onStreamFinished: {
            if (text.trim())
                console.warn("ThemeService:", text.trim());
        }
    }
}
