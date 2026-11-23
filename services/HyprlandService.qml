pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

import qs.config

Singleton {
    id: root

    // Bound (not read on demand) so Quickshell detects Lua mode at startup; a first lazy read returns false.
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

    // The screen is being captured (recording/sharing). Hyprland also reports a
    // brief capture for every screenshot, so only flag captures lasting a moment.
    // shortcut: one shared state, so with two capturing clients the first to stop clears it.
    property bool screencasting: false

    // Special workspace showing per monitor name, without "special:"; and the last one shown anywhere.
    property var specialByMonitor: ({})
    property string lastShownSpecial: ""

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

    // Show or hide a special workspace; no name means the last one shown.
    function toggleSpecialWorkspace(name) {
        const target = name || root.lastShownSpecial || "special";
        if (root.usingLua)
            Hyprland.dispatch(`hl.dsp.workspace.toggle_special("${target}")`);
        else
            Hyprland.dispatch(`togglespecialworkspace ${target}`);
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

        interval: 1000
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
