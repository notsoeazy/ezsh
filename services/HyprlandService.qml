pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

import qs.config

Singleton {
    id: root

    // The screen is being captured (recording/sharing).
    property bool screencasting: false

    // Special workspace showing per monitor name
    property var specialByMonitor: ({})
    property string lastShownSpecial: ""

    readonly property int screencastDebounceInterval: 1000

    readonly property bool usingLua: Hyprland.usingLua

    readonly property string focusedMonitorName: Hyprland.focusedMonitor?.name ?? ""

    // Workspaces are shown in pages of `Config.bar.workspacesPerPage`: 1..5, 6..10, ...
    readonly property int workspacesPerPage: Math.max(1, Config.bar.workspacesPerPage)

    // activeToplevel is null until the first focus event after startup.
    readonly property var activeWindow: Hyprland.activeToplevel ?? Hyprland.toplevels.values.find(t => t.wayland?.activated) ?? null
    readonly property string activeAppId: root.activeWindow?.wayland?.appId ?? root.activeWindow?.lastIpcObject.class ?? ""

    // Workspace ids that currently hold at least one window.
    readonly property var occupiedWorkspaceIds: {
        const ids = {};
        for (const workspace of Hyprland.workspaces.values)
            if (workspace.toplevels.values.length > 0)
                ids[workspace.id] = true;
        return ids;
    }

    // The Hyprland monitor behind a Quickshell screen (each bar asks for its own).
    function monitorFor(screen) {
        return screen ? Hyprland.monitorFor(screen) : null;
    }

    // A true fullscreen window (mode 2+) on the workspace; maximized (mode 1) doesn't count.
    // `hasFullscreen` reacts instantly but includes maximized, and the mode comes from cached IPC data
    // refreshed on every "fullscreen" event.
    function isTrueFullscreen(workspace) {
        return (workspace?.hasFullscreen ?? false) && workspace.toplevels.values.some(t => (t.lastIpcObject.fullscreen ?? 0) >= 2);
    }

    // Fullscreen on what the monitor shows: an open special workspace sits over the regular one.
    function isFullscreenOn(monitor) {
        const special = root.specialNameOn(monitor?.name ?? "");
        if (special)
            return root.isTrueFullscreen(Hyprland.workspaces.values.find(w => w.name === "special:" + special));
        return root.isTrueFullscreen(monitor?.activeWorkspace);
    }

    // A fullscreen window under an open special workspace: Hyprland still covers the top layer
    // with it, so the shell must draw on the overlay layer to stay visible.
    function hasFullscreenUnderSpecial(monitor) {
        return root.specialNameOn(monitor?.name ?? "") !== "" && root.isTrueFullscreen(monitor?.activeWorkspace);
    }

    // Global rects of the windows shown on a monitor, topmost first: an open special workspace, then
    // floating, then most recently focused. Reads cached IPC data; call refreshWindows() first.
    function windowsOn(monitorName) {
        const monitor = Hyprland.monitors.values.find(m => m.name === monitorName);
        const special = root.specialNameOn(monitorName);
        const shown = [monitor?.activeWorkspace?.name, special ? "special:" + special : null];
        return Hyprland.toplevels.values
            .map(t => t.lastIpcObject)
            .filter(w => w?.at && w.mapped && !w.hidden && shown.includes(w.workspace?.name))
            .sort((a, b) => (b.workspace.name.startsWith("special:") - a.workspace.name.startsWith("special:")) || (b.floating - a.floating) || (a.focusHistoryID - b.focusHistoryID))
            .map(w => Qt.rect(w.at[0], w.at[1], w.size[0], w.size[1]));
    }

    function refreshWindows() {
        Hyprland.refreshToplevels();
    }

    // Special workspaces (id < 1) fall back to the first page.
    function pageOffsetOf(id) {
        return id < 1 ? 0 : Math.floor((id - 1) / root.workspacesPerPage) * root.workspacesPerPage;
    }

    function specialNameOn(monitorName) {
        return root.specialByMonitor[monitorName] ?? "";
    }

    function isWorkspaceOccupied(id) {
        return root.occupiedWorkspaceIds[id] === true;
    }

    function switchToWorkspace(id) {
        if (id < 1)
            return;
        // Lua configs use the hl.dsp API; legacy dispatchers are ignored there.
        if (root.usingLua)
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
        else
            Hyprland.dispatch(`workspace ${id}`);
    }

    // The first window whose app id or class is appId (case and punctuation ignored), or null.
    function windowOfApp(appId) {
        const key = root.appKey(appId);
        if (!key)
            return null;
        return Hyprland.toplevels.values.find(t => [t.wayland?.appId, t.lastIpcObject?.class, t.lastIpcObject?.initialClass]
            .some(name => root.appKey(name) === key)) ?? null;
    }

    function appKey(name) {
        return (name ?? "").toLowerCase().replace(/[^a-z0-9]/g, "");
    }

    // Focuses a window, switching to its workspace.
    function focusWindow(window) {
        if (!window?.address)
            return;
        if (root.usingLua)
            Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${window.address}" })`);
        else
            Hyprland.dispatch(`focuswindow address:0x${window.address}`);
    }

    // Show or hide a special workspace; no name means the last one shown.
    function toggleSpecialWorkspace(name) {
        const target = name || root.lastShownSpecial || "special";
        if (root.usingLua)
            Hyprland.dispatch(`hl.dsp.workspace.toggle_special("${target}")`);
        else
            Hyprland.dispatch(`togglespecialworkspace ${target}`);
    }

    // Ends the Hyprland session (log out).
    function setDpms(on) {
        if (root.usingLua)
            Hyprland.dispatch(`hl.dsp.dpms({ action = "${on ? "enable" : "disable"}" })`);
        else
            Hyprland.dispatch(on ? "dpms on" : "dpms off");
    }

    function exit() {
        // shortcut: the Lua name hl.dsp.exit() is assumed from the dispatcher naming, verify on a Lua config.
        if (root.usingLua)
            Hyprland.dispatch("hl.dsp.exit()");
        else
            Hyprland.dispatch("exit");
    }

    function recordSpecial(monitorName, name) {
        const special = name.startsWith("special:") ? name.slice(8) : "";
        // New object so bindings on `specialByMonitor` re-evaluate.
        root.specialByMonitor = Object.assign({}, root.specialByMonitor, { [monitorName]: special });
        if (special)
            root.lastShownSpecial = special;
    }

    // "activespecial>>name,monitor"; name is empty when it is put away.
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "fullscreen")
                Hyprland.refreshToplevels();
            else if (event.name === "activespecial") {
                const [name, monitor] = event.data.split(",");
                root.recordSpecial(monitor, name);
            }
            else if (event.name === "screencast") {
                const on = event.data.startsWith("1");
                if (on)
                    screencastDebounce.restart();
                else {
                    screencastDebounce.stop();
                    root.screencasting = false;
                }
            }
        }
    }

    Timer {
        id: screencastDebounce

        interval: root.screencastDebounceInterval
        onTriggered: root.screencasting = true
    }

    // One may already be showing when the shell starts.
    Process {
        running: true
        command: ["hyprctl", "monitors", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    for (const m of JSON.parse(text))
                        root.recordSpecial(m.name, m.specialWorkspace?.name ?? "");
                } catch (e) {}
            }
        }
    }
}
