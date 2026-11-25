pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Whether the settings window is open, and the page it was asked to show.
Singleton {
    id: root

    property bool shown: false
    // The page asked for by the last open(); "" leaves the window on its current or first page.
    property string page: ""

    function open(page) {
        // A bar view keeps the keyboard and would sit over the window.
        ViewService.close();
        root.page = page ?? "";
        root.shown = true;
    }

    function close() {
        root.shown = false;
    }

    function toggle(page) {
        if (root.shown)
            root.close();
        else
            root.open(page);
    }

    // qs ipc call settings toggle
    // qs ipc call settings openPage clock
    IpcHandler {
        target: "settings"

        function open(): void {
            root.open("");
        }

        function openPage(page: string): void {
            root.open(page);
        }

        function toggle(): void {
            root.toggle("");
        }

        function close(): void {
            root.close();
        }
    }
}
