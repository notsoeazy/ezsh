pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

import qs.config

import "paging.js" as Paging

Singleton {
    id: root

    // Bound (not read on demand) so Quickshell detects Lua mode at startup; a first lazy read returns false.
    readonly property bool usingLua: Hyprland.usingLua

    readonly property string focusedMonitor: Hyprland.focusedMonitor?.name ?? ""

    // Workspaces are shown in pages of `Config.bar.workspaces`: 1..5, 6..10, ...
    readonly property int pageSize: Math.max(1, Config.bar.workspaces)

    // activeToplevel is null until the first focus event after startup.
    readonly property var activeWindow: Hyprland.activeToplevel ?? Hyprland.toplevels.values.find(t => t.wayland?.activated) ?? null
    readonly property string appId: root.activeWindow?.wayland?.appId ?? root.activeWindow?.lastIpcObject.class ?? ""

    // Workspace ids that currently hold at least one window.
    readonly property var occupied: {
        const ids = {};
        for (const ws of Hyprland.workspaces.values)
            if (ws.toplevels.values.length > 0)
                ids[ws.id] = true;
        return ids;
    }

    // The screen is being captured (recording/sharing). Hyprland also reports a
    // brief capture for every screenshot, so only flag captures lasting a moment.
    // shortcut: one shared state, so with two capturing clients the first to stop clears it.
    property bool screencasting: false

    // Special workspace showing per monitor name, without "special:"; and the last one shown anywhere.
    property var specials: ({})
    property string lastSpecial: ""

    // The Hyprland monitor behind a Quickshell screen (each bar asks for its own).
    function monitorFor(screen) {
        return screen ? Hyprland.monitorFor(screen) : null;
    }

    // A true fullscreen window (mode 2+) on the monitor's workspace; maximized (mode 1) doesn't count.
    // `hasFullscreen` reacts instantly but includes maximized, and the mode comes from cached IPC data
    // refreshed on every "fullscreen" event.
    function fullscreenOn(monitor) {
        const ws = monitor?.activeWorkspace;
        return (ws?.hasFullscreen ?? false) && ws.toplevels.values.some(t => (t.lastIpcObject.fullscreen ?? 0) >= 2);
    }

    function pageStart(id) {
        return Paging.pageStart(id, root.pageSize);
    }

    function specialOn(monitorName) {
        return root.specials[monitorName] ?? "";
    }

    function isOccupied(id) {
        return root.occupied[id] === true;
    }

    function switchTo(id) {
        if (id < 1)
            return;
        // Lua configs use the hl.dsp API; legacy dispatchers are ignored there.
        if (root.usingLua)
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
        else
            Hyprland.dispatch(`workspace ${id}`);
    }

    // Show or hide a special workspace; no name means the last one shown.
    function toggleSpecial(name) {
        const target = name || root.lastSpecial || "special";
        if (root.usingLua)
            Hyprland.dispatch(`hl.dsp.workspace.toggle_special("${target}")`);
        else
            Hyprland.dispatch(`togglespecialworkspace ${target}`);
    }

    function setSpecial(monitorName, name) {
        const special = name.startsWith("special:") ? name.slice(8) : "";
        // New object so bindings on `specials` re-evaluate.
        root.specials = Object.assign({}, root.specials, { [monitorName]: special });
        if (special)
            root.lastSpecial = special;
    }

    // "activespecial>>name,monitor"; name is empty when it is put away.
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "fullscreen")
                Hyprland.refreshToplevels();
            else if (event.name === "activespecial") {
                const [name, monitor] = event.data.split(",");
                root.setSpecial(monitor, name);
            }
            else if (event.name === "screencast") {
                const on = event.data.startsWith("1");
                if (on)
                    screencastDelay.restart();
                else {
                    screencastDelay.stop();
                    root.screencasting = false;
                }
            }
        }
    }

    Timer {
        id: screencastDelay

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
                        root.setSpecial(m.name, m.specialWorkspace?.name ?? "");
                } catch (e) {}
            }
        }
    }
}
