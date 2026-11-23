pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string view: ""
    property string page: ""
    property string monitorName: ""

    // Opens view on a monitor (default: the focused one), optionally on one of its pages.
    function open(view, page, monitorName) {
        root.monitorName = monitorName || root.targetMonitorName();
        root.page = page ?? "";
        root.view = view;
    }

    function close() {
        // Order matters: LauncherView reopens a page when page changes while view is still "launcher", so clear view first or closing would reopen it.
        root.view = "";
        root.page = "";
    }

    // Closes view if it is open on that page on the focused monitor; otherwise opens it there (moving it if it was open on another monitor).
    function toggle(view, page) {
        if (root.view === view && root.page === (page ?? "") && root.monitorName === root.targetMonitorName())
            root.close();
        else
            root.open(view, page);
    }

    // The focused monitor, or the first screen before Hyprland has reported focus, so a view never opens on a monitor no bar is drawn on.
    function targetMonitorName() {
        return HyprlandService.focusedMonitorName || (Quickshell.screens[0]?.name ?? "");
    }

    // qs ipc call view toggle launcher
    // qs ipc call view togglePage launcher clipboard
    IpcHandler {
        target: "view"

        function open(view: string): void {
            root.open(view, "");
        }

        function openPage(view: string, page: string): void {
            root.open(view, page);
        }

        function toggle(view: string): void {
            root.toggle(view, "");
        }

        function togglePage(view: string, page: string): void {
            root.toggle(view, page);
        }

        function close(): void {
            root.close();
        }
    }
}
